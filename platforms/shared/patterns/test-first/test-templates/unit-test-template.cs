using Xunit;
using FluentAssertions;
using NSubstitute;

namespace YourApp.Tests.Unit;

// Unit Test Template - Test-First Development
// Write these BEFORE implementation

public class EntityTests
{
    // Test class naming: [ClassUnderTest]Tests
    // Test method naming: [MethodUnderTest]_[Scenario]_[ExpectedBehavior]

    #region Create Tests

    [Fact]
    public void Create_ValidParameters_ReturnsEntity()
    {
        // Arrange
        var name = "Test Entity";
        var description = "Test Description";

        // Act
        var entity = Entity.Create(name, description);

        // Assert
        entity.Should().NotBeNull();
        entity.Id.Should().NotBe(Guid.Empty);
        entity.Name.Should().Be(name);
        entity.Description.Should().Be(description);
        entity.CreatedAt.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromSeconds(1));
    }

    [Fact]
    public void Create_NullName_ThrowsDomainException()
    {
        // Arrange
        string name = null;
        var description = "Test Description";

        // Act
        Action act = () => Entity.Create(name, description);

        // Assert
        act.Should().Throw<DomainException>()
            .WithMessage("*Name*required*");
    }

    [Theory]
    [InlineData("")]
    [InlineData(" ")]
    [InlineData("  ")]
    public void Create_EmptyOrWhitespaceName_ThrowsDomainException(string invalidName)
    {
        // Arrange
        var description = "Test Description";

        // Act
        Action act = () => Entity.Create(invalidName, description);

        // Assert
        act.Should().Throw<DomainException>()
            .WithMessage("*Name*required*");
    }

    #endregion

    #region UpdateName Tests

    [Fact]
    public void UpdateName_ValidName_UpdatesSuccessfully()
    {
        // Arrange
        var entity = Entity.Create("Original Name", "Description");
        var newName = "Updated Name";

        // Act
        entity.UpdateName(newName);

        // Assert
        entity.Name.Should().Be(newName);
    }

    [Fact]
    public void UpdateName_NullName_ThrowsDomainException()
    {
        // Arrange
        var entity = Entity.Create("Original Name", "Description");

        // Act
        Action act = () => entity.UpdateName(null);

        // Assert
        act.Should().Throw<DomainException>();
    }

    #endregion
}

// Command Handler Unit Test Template
public class CreateEntityCommandHandlerTests
{
    private readonly IRepository<Entity> _repository;
    private readonly ILogger<CreateEntityCommandHandler> _logger;
    private readonly CreateEntityCommandHandler _handler;

    public CreateEntityCommandHandlerTests()
    {
        // Setup mocks in constructor for reuse
        _repository = Substitute.For<IRepository<Entity>>();
        _logger = Substitute.For<ILogger<CreateEntityCommandHandler>>();
        _handler = new CreateEntityCommandHandler(_repository, _logger);
    }

    [Fact]
    public async Task Handle_ValidCommand_CreatesEntityAndReturnsId()
    {
        // Arrange
        var command = new CreateEntityCommand(
            Name: "Test Entity",
            Description: "Test Description");

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        result.Should().NotBe(Guid.Empty);
        await _repository.Received(1).AddAsync(
            Arg.Is<Entity>(e =>
                e.Name == command.Name &&
                e.Description == command.Description),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_RepositoryThrowsException_PropagatesException()
    {
        // Arrange
        var command = new CreateEntityCommand("Test", "Description");
        _repository.AddAsync(Arg.Any<Entity>(), Arg.Any<CancellationToken>())
            .Throws(new Exception("Database error"));

        // Act
        Func<Task> act = async () =>
            await _handler.Handle(command, CancellationToken.None);

        // Assert
        await act.Should().ThrowAsync<Exception>()
            .WithMessage("Database error");
    }

    [Fact]
    public async Task Handle_ValidCommand_LogsInformation()
    {
        // Arrange
        var command = new CreateEntityCommand("Test", "Description");

        // Act
        await _handler.Handle(command, CancellationToken.None);

        // Assert
        _logger.Received().LogInformation(
            Arg.Is<string>(s => s.Contains("Creating entity")),
            Arg.Any<object[]>());
    }
}

// Query Handler Unit Test Template
public class GetEntityByIdQueryHandlerTests
{
    private readonly IReadRepository<Entity> _repository;
    private readonly ILogger<GetEntityByIdQueryHandler> _logger;
    private readonly GetEntityByIdQueryHandler _handler;

    public GetEntityByIdQueryHandlerTests()
    {
        _repository = Substitute.For<IReadRepository<Entity>>();
        _logger = Substitute.For<ILogger<GetEntityByIdQueryHandler>>();
        _handler = new GetEntityByIdQueryHandler(_repository, _logger);
    }

    [Fact]
    public async Task Handle_ExistingEntity_ReturnsDto()
    {
        // Arrange
        var entityId = Guid.NewGuid();
        var entity = CreateTestEntity(entityId);

        _repository.GetByIdAsync(entityId, Arg.Any<CancellationToken>())
            .Returns(entity);

        var query = new GetEntityByIdQuery(entityId);

        // Act
        var result = await _handler.Handle(query, CancellationToken.None);

        // Assert
        result.Should().NotBeNull();
        result.Id.Should().Be(entityId);
        result.Name.Should().Be(entity.Name);
    }

    [Fact]
    public async Task Handle_NonExistingEntity_ThrowsNotFoundException()
    {
        // Arrange
        var query = new GetEntityByIdQuery(Guid.NewGuid());
        _repository.GetByIdAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>())
            .Returns((Entity)null);

        // Act
        Func<Task> act = async () =>
            await _handler.Handle(query, CancellationToken.None);

        // Assert
        await act.Should().ThrowAsync<NotFoundException>();
    }

    // Helper method for creating test data
    private Entity CreateTestEntity(Guid id)
    {
        return new Entity
        {
            Id = id,
            Name = "Test Entity",
            Description = "Test Description",
            CreatedAt = DateTime.UtcNow
        };
    }
}

// Validator Unit Test Template
public class CreateEntityCommandValidatorTests
{
    private readonly CreateEntityCommandValidator _validator;

    public CreateEntityCommandValidatorTests()
    {
        _validator = new CreateEntityCommandValidator();
    }

    [Fact]
    public async Task Validate_ValidCommand_ReturnsValid()
    {
        // Arrange
        var command = new CreateEntityCommand(
            Name: "Valid Name",
            Description: "Valid Description");

        // Act
        var result = await _validator.ValidateAsync(command);

        // Assert
        result.IsValid.Should().BeTrue();
        result.Errors.Should().BeEmpty();
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData(" ")]
    public async Task Validate_InvalidName_ReturnsInvalid(string invalidName)
    {
        // Arrange
        var command = new CreateEntityCommand(
            Name: invalidName,
            Description: "Valid Description");

        // Act
        var result = await _validator.ValidateAsync(command);

        // Assert
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e =>
            e.PropertyName == nameof(command.Name));
    }

    [Fact]
    public async Task Validate_NameTooLong_ReturnsInvalid()
    {
        // Arrange
        var command = new CreateEntityCommand(
            Name: new string('a', 101), // Exceeds 100 char limit
            Description: "Valid Description");

        // Act
        var result = await _validator.ValidateAsync(command);

        // Assert
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e =>
            e.PropertyName == nameof(command.Name) &&
            e.ErrorMessage.Contains("100"));
    }
}

// Test-First Development Process:
// 1. Write failing test (RED)
// 2. Write minimal code to pass (GREEN)
// 3. Refactor while keeping tests green (REFACTOR)
// 4. Aim for >80% code coverage
// 5. Test edge cases and error scenarios
