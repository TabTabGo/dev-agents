# Architecture Guide

This guide explains the universal architecture patterns used across all AI platforms in this repository.

## Core Principles

1. **Clean Architecture** - Business logic independent of frameworks
2. **CQRS** - Commands modify, Queries read
3. **Test-First** - Write tests before implementation
4. **Quality** - Minimum 80% code coverage required

## Technology Stacks

### Backend (.NET/C#)
- **Framework**: .NET 8+
- **CQRS**: MediatR
- **Validation**: FluentValidation
- **ORM**: Entity Framework Core
- **Testing**: xUnit, FluentAssertions, NSubstitute

### Frontend (React)
- **Framework**: React 18+
- **State**: Context API or Redux (for complex state)
- **Routing**: React Router
- **Testing**: Vitest, React Testing Library

## Layer Responsibilities

### Domain Layer
- **Purpose**: Contains business logic and rules
- **Dependencies**: None
- **Files**: Entities, Value Objects, Domain Events, Exceptions
- **Example**: `Order`, `OrderLine`, `Money` (value object)

### Application Layer
- **Purpose**: Orchestrates use cases
- **Dependencies**: Domain only
- **Files**: Commands, Queries, Handlers, Validators, DTOs, Interfaces
- **Example**: `CreateOrderCommand`, `CreateOrderCommandHandler`

### Infrastructure Layer
- **Purpose**: Implements external concerns
- **Dependencies**: Application, Domain
- **Files**: DbContext, Repositories, External Services, Caching
- **Example**: `OrderRepository`, `EmailService`

### Presentation Layer
- **Purpose**: Handles user interaction (API or UI)
- **Dependencies**: Application (registers Infrastructure)
- **Files**: Controllers, Middleware, Request/Response models
- **Example**: `OrdersController`, `ErrorHandlingMiddleware`

## CQRS Patterns

### Commands
```csharp
// Intention to modify state
public record CreateOrderCommand(Guid CustomerId) : IRequest<Guid>;

// Handler executes the command
public class CreateOrderCommandHandler : IRequestHandler<CreateOrderCommand, Guid>
{
    public async Task<Guid> Handle(CreateOrderCommand request, CancellationToken ct)
    {
        var order = Order.Create(request.CustomerId);
        await _repository.AddAsync(order, ct);
        return order.Id;
    }
}
```

### Queries
```csharp
// Request for data
public record GetOrderQuery(Guid OrderId) : IRequest<OrderDto>;

// Handler retrieves data
public class GetOrderQueryHandler : IRequestHandler<GetOrderQuery, OrderDto>
{
    public async Task<OrderDto> Handle(GetOrderQuery request, CancellationToken ct)
    {
        var order = await _repository.GetByIdAsync(request.OrderId, ct);
        return order.ToDto();
    }
}
```

## Testing Strategy

### Test Pyramid
```
       /\
      /  \     E2E Tests (Few)
     /----\
    /      \   Integration Tests (Some)
   /--------\
  /          \ Unit Tests (Many)
 /____________\
```

### Unit Tests (>80% coverage required)
- Test Domain entities and business rules
- Test Command/Query handlers with mocked dependencies
- Test Validators
- Fast, isolated, deterministic

### Integration Tests
- Test Infrastructure layer (repositories, database)
- Test API endpoints
- Use test database or containers

### E2E Tests
- Test critical user journeys
- Minimal set covering happy paths
- Use real browser for frontend

## File Organization

### Backend (.NET)
```
src/
├── YourApp.Domain/
│   ├── Entities/
│   │   └── Order.cs
│   ├── ValueObjects/
│   │   └── Money.cs
│   └── Exceptions/
│       └── DomainException.cs
│
├── YourApp.Application/
│   ├── Commands/
│   │   ├── CreateOrder/
│   │   │   ├── CreateOrderCommand.cs
│   │   │   ├── CreateOrderCommandHandler.cs
│   │   │   └── CreateOrderCommandValidator.cs
│   └── Queries/
│       └── GetOrder/
│           ├── GetOrderQuery.cs
│           └── GetOrderQueryHandler.cs
│
├── YourApp.Infrastructure/
│   ├── Persistence/
│   │   ├── AppDbContext.cs
│   │   └── Configurations/
│   │       └── OrderConfiguration.cs
│   └── Repositories/
│       └── OrderRepository.cs
│
└── YourApp.API/
    ├── Controllers/
    │   └── OrdersController.cs
    └── Program.cs

tests/
├── YourApp.UnitTests/
│   ├── Domain/
│   ├── Application/
│   └── API/
│
└── YourApp.IntegrationTests/
    ├── Infrastructure/
    └── API/
```

### Frontend (React)
```
src/
├── features/
│   └── orders/
│       ├── components/
│       │   ├── OrderList.tsx
│       │   └── OrderDetails.tsx
│       ├── hooks/
│       │   └── useOrders.ts
│       └── api/
│           └── ordersApi.ts
│
├── shared/
│   ├── components/
│   ├── hooks/
│   └── utils/
│
└── App.tsx

tests/
└── features/
    └── orders/
        └── OrderList.test.tsx
```

## Best Practices

### Do's
- ✅ Write tests first
- ✅ Keep domain pure (no framework dependencies)
- ✅ Use value objects for complex types
- ✅ Validate at application layer
- ✅ Return DTOs from queries (not entities)
- ✅ Use async/await with CancellationToken
- ✅ Log meaningful information
- ✅ Handle errors appropriately at each layer

### Don'ts
- ❌ Don't put business logic in controllers
- ❌ Don't use entities as DTOs
- ❌ Don't skip validation
- ❌ Don't ignore cancellation tokens
- ❌ Don't catch and swallow exceptions
- ❌ Don't mix commands and queries
- ❌ Don't create dependencies from inner to outer layers
- ❌ Don't skip tests to save time

## Common Patterns

### Result Pattern (for operations that can fail)
```csharp
public class Result<T>
{
    public bool IsSuccess { get; }
    public T Value { get; }
    public string Error { get; }

    public static Result<T> Success(T value) => new(true, value, null);
    public static Result<T> Failure(string error) => new(false, default, error);
}
```

### Repository Pattern
```csharp
public interface IRepository<T> where T : Entity
{
    Task<T> GetByIdAsync(Guid id, CancellationToken ct);
    Task<List<T>> GetAllAsync(CancellationToken ct);
    Task AddAsync(T entity, CancellationToken ct);
    Task UpdateAsync(T entity, CancellationToken ct);
    Task DeleteAsync(Guid id, CancellationToken ct);
}
```

### Specification Pattern (for complex queries)
```csharp
public abstract class Specification<T>
{
    public abstract Expression<Func<T, bool>> ToExpression();
    public bool IsSatisfiedBy(T entity) => ToExpression().Compile()(entity);
}
```

## Performance Considerations

1. **Query Optimization** - Use projections, avoid N+1 queries
2. **Caching** - Cache expensive query results
3. **Pagination** - Always paginate list queries
4. **Async** - Use async/await for I/O operations
5. **Lazy Loading** - Avoid lazy loading, use eager loading explicitly

## Security

1. **Validation** - Always validate input at application layer
2. **Authorization** - Check permissions before executing commands
3. **Sanitization** - Sanitize user input to prevent injection
4. **HTTPS** - Always use HTTPS in production
5. **Secrets** - Never commit secrets, use environment variables

## Monitoring

1. **Logging** - Log important events (structured logging)
2. **Metrics** - Track performance metrics
3. **Tracing** - Use distributed tracing for microservices
4. **Health Checks** - Implement health check endpoints
5. **Alerts** - Set up alerts for critical failures
