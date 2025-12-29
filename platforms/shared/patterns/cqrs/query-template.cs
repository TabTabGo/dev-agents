using MediatR;

namespace YourApp.Application.Queries;

// Query - Represents a request for data
// Queries should NEVER modify state
public record GetEntityByIdQuery(Guid EntityId)
    : IRequest<EntityDto>;

// Query Response DTO - Data Transfer Object
public record EntityDto(
    Guid Id,
    string Name,
    string Description,
    DateTime CreatedAt);

// Query Handler - Retrieves data
public class GetEntityByIdQueryHandler
    : IRequestHandler<GetEntityByIdQuery, EntityDto>
{
    private readonly IReadRepository<Entity> _repository;
    private readonly ILogger<GetEntityByIdQueryHandler> _logger;

    public GetEntityByIdQueryHandler(
        IReadRepository<Entity> repository,
        ILogger<GetEntityByIdQueryHandler> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<EntityDto> Handle(
        GetEntityByIdQuery request,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation(
            "Retrieving entity with ID: {EntityId}",
            request.EntityId);

        var entity = await _repository.GetByIdAsync(
            request.EntityId,
            cancellationToken);

        if (entity == null)
        {
            throw new NotFoundException(
                $"Entity with ID {request.EntityId} not found");
        }

        // Map to DTO
        return new EntityDto(
            entity.Id,
            entity.Name,
            entity.Description,
            entity.CreatedAt);
    }
}

// List Query Example
public record GetEntitiesQuery(
    int PageNumber = 1,
    int PageSize = 10,
    string? SearchTerm = null
) : IRequest<PagedResult<EntityDto>>;

public record PagedResult<T>(
    List<T> Items,
    int TotalCount,
    int PageNumber,
    int PageSize)
{
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);
    public bool HasPrevious => PageNumber > 1;
    public bool HasNext => PageNumber < TotalPages;
}

public class GetEntitiesQueryHandler
    : IRequestHandler<GetEntitiesQuery, PagedResult<EntityDto>>
{
    private readonly IReadRepository<Entity> _repository;

    public GetEntitiesQueryHandler(IReadRepository<Entity> repository)
    {
        _repository = repository;
    }

    public async Task<PagedResult<EntityDto>> Handle(
        GetEntitiesQuery request,
        CancellationToken cancellationToken)
    {
        var query = _repository.GetAll();

        // Apply search filter
        if (!string.IsNullOrWhiteSpace(request.SearchTerm))
        {
            query = query.Where(e =>
                e.Name.Contains(request.SearchTerm) ||
                e.Description.Contains(request.SearchTerm));
        }

        // Get total count
        var totalCount = await query.CountAsync(cancellationToken);

        // Apply pagination
        var items = await query
            .OrderBy(e => e.Name)
            .Skip((request.PageNumber - 1) * request.PageSize)
            .Take(request.PageSize)
            .Select(e => new EntityDto(
                e.Id,
                e.Name,
                e.Description,
                e.CreatedAt))
            .ToListAsync(cancellationToken);

        return new PagedResult<EntityDto>(
            items,
            totalCount,
            request.PageNumber,
            request.PageSize);
    }
}

// Unit Test Example
public class GetEntityByIdQueryHandlerTests
{
    [Fact]
    public async Task Handle_ExistingEntity_ReturnsDto()
    {
        // Arrange
        var entityId = Guid.NewGuid();
        var entity = new Entity
        {
            Id = entityId,
            Name = "Test Entity",
            Description = "Test Description",
            CreatedAt = DateTime.UtcNow
        };

        var repository = Substitute.For<IReadRepository<Entity>>();
        repository.GetByIdAsync(entityId, Arg.Any<CancellationToken>())
            .Returns(entity);

        var logger = Substitute.For<ILogger<GetEntityByIdQueryHandler>>();
        var handler = new GetEntityByIdQueryHandler(repository, logger);

        var query = new GetEntityByIdQuery(entityId);

        // Act
        var result = await handler.Handle(query, CancellationToken.None);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(entityId);
        result.Name.Should().Be("Test Entity");
    }

    [Fact]
    public async Task Handle_NonExistingEntity_ThrowsNotFoundException()
    {
        // Arrange
        var repository = Substitute.For<IReadRepository<Entity>>();
        repository.GetByIdAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns((Entity)null);

        var logger = Substitute.For<ILogger<GetEntityByIdQueryHandler>>();
        var handler = new GetEntityByIdQueryHandler(repository, logger);

        var query = new GetEntityByIdQuery(Guid.NewGuid());

        // Act & Assert
        await Assert.ThrowsAsync<NotFoundException>(
            () => handler.Handle(query, CancellationToken.None));
    }
}

// Cached Query Example (for expensive/frequently accessed data)
public class GetEntityByIdCachedQueryHandler
    : IRequestHandler<GetEntityByIdQuery, EntityDto>
{
    private readonly IReadRepository<Entity> _repository;
    private readonly ICache _cache;
    private const string CacheKeyPrefix = "entity:";

    public async Task<EntityDto> Handle(
        GetEntityByIdQuery request,
        CancellationToken cancellationToken)
    {
        var cacheKey = $"{CacheKeyPrefix}{request.EntityId}";

        // Try cache first
        var cached = await _cache.GetAsync<EntityDto>(cacheKey);
        if (cached != null)
            return cached;

        // Query database
        var entity = await _repository.GetByIdAsync(
            request.EntityId,
            cancellationToken);

        if (entity == null)
            throw new NotFoundException($"Entity {request.EntityId} not found");

        var dto = new EntityDto(
            entity.Id,
            entity.Name,
            entity.Description,
            entity.CreatedAt);

        // Cache for 5 minutes
        await _cache.SetAsync(cacheKey, dto, TimeSpan.FromMinutes(5));

        return dto;
    }
}
