using MediatR;

namespace YourApp.Application.Commands;

// Command - Represents an intention to change state
// Commands should return void or just an ID
public record CreateEntityCommand(
    string Name,
    string Description
) : IRequest<Guid>; // Returns the ID of created entity

// Command Handler - Executes the command
public class CreateEntityCommandHandler
    : IRequestHandler<CreateEntityCommand, Guid>
{
    private readonly IRepository<Entity> _repository;
    private readonly ILogger<CreateEntityCommandHandler> _logger;

    public CreateEntityCommandHandler(
        IRepository<Entity> repository,
        ILogger<CreateEntityCommandHandler> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    public async Task<Guid> Handle(
        CreateEntityCommand request,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation(
            "Creating entity with name: {Name}",
            request.Name);

        // 1. Create domain entity (business logic in domain)
        var entity = Entity.Create(
            request.Name,
            request.Description);

        // 2. Persist using repository
        await _repository.AddAsync(entity, cancellationToken);

        _logger.LogInformation(
            "Entity created with ID: {EntityId}",
            entity.Id);

        // 3. Return identifier
        return entity.Id;
    }
}

// Command Validator - Uses FluentValidation
public class CreateEntityCommandValidator
    : AbstractValidator<CreateEntityCommand>
{
    public CreateEntityCommandValidator()
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .MaximumLength(100)
            .WithMessage("Name is required and must be less than 100 characters");

        RuleFor(x => x.Description)
            .MaximumLength(500)
            .WithMessage("Description must be less than 500 characters");
    }
}

// Unit Test Example
public class CreateEntityCommandHandlerTests
{
    [Fact]
    public async Task Handle_ValidCommand_CreatesEntityAndReturnsId()
    {
        // Arrange
        var repository = Substitute.For<IRepository<Entity>>();
        var logger = Substitute.For<ILogger<CreateEntityCommandHandler>>();
        var handler = new CreateEntityCommandHandler(repository, logger);

        var command = new CreateEntityCommand(
            Name: "Test Entity",
            Description: "Test Description");

        // Act
        var result = await handler.Handle(command, CancellationToken.None);

        // Assert
        result.Should().NotBe(Guid.Empty);
        await repository.Received(1).AddAsync(
            Arg.Any<Entity>(),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_EmptyName_ThrowsValidationException()
    {
        // Arrange
        var validator = new CreateEntityCommandValidator();
        var command = new CreateEntityCommand(
            Name: "",
            Description: "Test Description");

        // Act
        var result = await validator.ValidateAsync(command);

        // Assert
        result.IsValid.Should().BeFalse();
        result.Errors.Should().Contain(e => e.PropertyName == nameof(command.Name));
    }
}
