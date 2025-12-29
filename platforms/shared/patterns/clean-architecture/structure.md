# Clean Architecture Structure

Clean Architecture organizes code into 4 distinct layers with strict dependency rules.

## The Four Layers

### 1. Domain Layer (Core)
**Dependencies**: NONE (innermost layer)

**Contains**:
- Entities - Business objects with identity
- Value Objects - Immutable objects without identity
- Domain Events - Things that happened in the domain
- Domain Exceptions - Business rule violations
- Interfaces (optional) - Domain services contracts

**Rules**:
- No dependencies on other layers or frameworks
- Rich domain models (not anemic)
- All business logic lives here
- Pure C# with no infrastructure concerns

**Example**:
```csharp
public class Order : Entity
{
    public Guid CustomerId { get; private set; }
    private List<OrderLine> _lines = new();
    public IReadOnlyList<OrderLine> Lines => _lines.AsReadOnly();

    public static Order Create(Guid customerId)
    {
        if (customerId == Guid.Empty)
            throw new DomainException("Customer ID required");

        return new Order { CustomerId = customerId };
    }

    public void AddLine(Product product, int quantity)
    {
        if (quantity <= 0)
            throw new DomainException("Quantity must be positive");

        _lines.Add(new OrderLine(product, quantity));
    }
}
```

### 2. Application Layer (Use Cases)
**Dependencies**: Domain layer only

**Contains**:
- Commands (CQRS) - Modify state
- Queries (CQRS) - Read data
- Command/Query Handlers (MediatR)
- Validators (FluentValidation)
- DTOs - Data transfer objects
- Interfaces - Repository contracts, external service contracts

**Rules**:
- Orchestrates domain objects
- No business logic (delegates to domain)
- No infrastructure concerns (uses interfaces)
- Implements use cases

**Example**:
```csharp
public record CreateOrderCommand(Guid CustomerId, List<OrderItemDto> Items)
    : IRequest<Guid>;

public class CreateOrderCommandHandler
    : IRequestHandler<CreateOrderCommand, Guid>
{
    private readonly IRepository<Order> _repository;

    public async Task<Guid> Handle(
        CreateOrderCommand request,
        CancellationToken cancellationToken)
    {
        var order = Order.Create(request.CustomerId);

        foreach (var item in request.Items)
        {
            order.AddLine(item.Product, item.Quantity);
        }

        await _repository.AddAsync(order, cancellationToken);
        return order.Id;
    }
}
```

### 3. Infrastructure Layer (Implementation)
**Dependencies**: Application and Domain layers

**Contains**:
- Database context (EF Core)
- Repository implementations
- External service implementations
- File system access
- Email/SMS services
- Caching implementations

**Rules**:
- Implements interfaces defined in Application layer
- Contains all framework-specific code
- Can be swapped without affecting business logic

**Example**:
```csharp
public class OrderRepository : IRepository<Order>
{
    private readonly AppDbContext _context;

    public async Task<Order> GetByIdAsync(
        Guid id,
        CancellationToken cancellationToken)
    {
        return await _context.Orders
            .Include(o => o.Lines)
            .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);
    }

    public async Task AddAsync(
        Order order,
        CancellationToken cancellationToken)
    {
        await _context.Orders.AddAsync(order, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
    }
}
```

### 4. Presentation Layer (API/UI)
**Dependencies**: Application layer (registers Infrastructure)

**Contains**:
- API Controllers or Minimal APIs
- Middleware
- Authentication/Authorization
- Request/Response models
- Dependency injection setup

**Rules**:
- Thin layer - just routing to use cases
- Handles HTTP concerns only
- Registers dependencies from Infrastructure

**Example**:
```csharp
[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    private readonly IMediator _mediator;

    [HttpPost]
    public async Task<ActionResult<Guid>> CreateOrder(
        CreateOrderRequest request,
        CancellationToken cancellationToken)
    {
        var command = new CreateOrderCommand(
            request.CustomerId,
            request.Items);

        var orderId = await _mediator.Send(command, cancellationToken);
        return CreatedAtAction(nameof(GetOrder), new { id = orderId }, orderId);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<OrderDto>> GetOrder(
        Guid id,
        CancellationToken cancellationToken)
    {
        var query = new GetOrderByIdQuery(id);
        var order = await _mediator.Send(query, cancellationToken);
        return Ok(order);
    }
}
```

## Dependency Rule

**The Dependency Rule**: Source code dependencies must point INWARD only.

```
┌─────────────────────────────────────────┐
│         Presentation (API/UI)           │  Depends on: Application
│                                         │  Registers: Infrastructure
├─────────────────────────────────────────┤
│         Infrastructure                  │  Depends on: Application, Domain
│  (EF, Repositories, External Services)  │
├─────────────────────────────────────────┤
│         Application (Use Cases)         │  Depends on: Domain
│      (Commands, Queries, DTOs)          │
├─────────────────────────────────────────┤
│         Domain (Business Logic)         │  Depends on: NOTHING
│    (Entities, Value Objects, Events)    │
└─────────────────────────────────────────┘
```

## Project Structure

```
src/
├── YourApp.Domain/
│   ├── Entities/
│   ├── ValueObjects/
│   ├── Events/
│   └── Exceptions/
│
├── YourApp.Application/
│   ├── Commands/
│   ├── Queries/
│   ├── Validators/
│   ├── DTOs/
│   └── Interfaces/
│
├── YourApp.Infrastructure/
│   ├── Persistence/
│   │   ├── Configurations/
│   │   └── AppDbContext.cs
│   ├── Repositories/
│   └── Services/
│
└── YourApp.API/
    ├── Controllers/
    ├── Middleware/
    └── Program.cs
```

## Benefits

1. **Testability** - Domain and Application layers are pure C# (no framework dependencies)
2. **Independence** - Business logic doesn't depend on UI, database, or frameworks
3. **Flexibility** - Swap infrastructure (SQL → NoSQL) without touching business logic
4. **Maintainability** - Clear separation of concerns
5. **Team Scalability** - Teams can work on different layers independently

## Common Mistakes to Avoid

1. ❌ Putting business logic in controllers
2. ❌ Domain entities depending on infrastructure (e.g., [Column] attributes)
3. ❌ Application layer implementing repository (belongs in Infrastructure)
4. ❌ Skipping the Application layer and calling repositories from controllers
5. ❌ Creating dependencies from inner to outer layers
