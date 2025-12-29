# Quality Standards

All code contributed to projects using this framework must meet these quality standards.

## Code Coverage

**Minimum Required**: 80%

### What to Test
- ✅ Domain entities and business logic (100% coverage target)
- ✅ Command and Query handlers (100% coverage target)
- ✅ Validators (100% coverage target)
- ✅ API controllers (happy path and error cases)
- ✅ Custom middleware and filters
- ⚠️ Repository implementations (integration tests)
- ❌ DTOs (no behavior to test)
- ❌ Configuration classes (no logic)

### Measuring Coverage
```bash
# .NET
dotnet test /p:CollectCoverage=true /p:CoverageReportsFolder=./coverage

# Generate HTML report
reportgenerator -reports:./coverage/coverage.cobertura.xml -targetdir:./coverage/html

# React
npm run test:coverage
```

## Test-First Development

### The Red-Green-Refactor Cycle

1. **RED** - Write a failing test
2. **GREEN** - Write minimal code to pass
3. **REFACTOR** - Improve code while keeping tests green

### Example
```csharp
// 1. RED - Write failing test
[Fact]
public void Create_ValidName_ReturnsOrder()
{
    var order = Order.Create(customerId);
    order.Should().NotBeNull();
    order.CustomerId.Should().Be(customerId);
}

// 2. GREEN - Minimal implementation
public static Order Create(Guid customerId)
{
    return new Order { CustomerId = customerId };
}

// 3. REFACTOR - Add validation
public static Order Create(Guid customerId)
{
    if (customerId == Guid.Empty)
        throw new DomainException("Customer ID required");

    return new Order { CustomerId = customerId };
}

// Add test for validation
[Fact]
public void Create_EmptyCustomerId_ThrowsException()
{
    Action act = () => Order.Create(Guid.Empty);
    act.Should().Throw<DomainException>();
}
```

## Code Style

### Naming Conventions

**C# / .NET**
- PascalCase: Classes, methods, properties, public fields
- camelCase: Private fields, local variables, parameters
- Interface prefix: `IRepository`, `IService`
- Async suffix: `GetOrderAsync`, `SaveChangesAsync`

**React / TypeScript**
- PascalCase: Components, interfaces, types
- camelCase: Functions, variables, hooks
- Hook prefix: `useOrders`, `useAuth`

### File Naming
- One class per file
- File name matches class name
- Group related files in folders (CQRS: `CreateOrder/` folder)

### Code Organization
```csharp
public class OrdersController : ControllerBase
{
    // 1. Fields
    private readonly IMediator _mediator;

    // 2. Constructor
    public OrdersController(IMediator mediator) => _mediator = mediator;

    // 3. Public methods
    [HttpPost]
    public async Task<ActionResult<Guid>> Create(...) { }

    [HttpGet("{id}")]
    public async Task<ActionResult<OrderDto>> Get(...) { }

    // 4. Private methods
    private void LogOrder(Order order) { }
}
```

## SOLID Principles

### Single Responsibility Principle
Each class should have ONE reason to change.

```csharp
// ❌ Bad - Multiple responsibilities
public class OrderService
{
    public void CreateOrder() { }
    public void SendEmail() { }
    public void GeneratePdf() { }
}

// ✅ Good - Single responsibility
public class OrderService { public void CreateOrder() { } }
public class EmailService { public void SendEmail() { } }
public class PdfGenerator { public void GeneratePdf() { } }
```

### Open/Closed Principle
Open for extension, closed for modification.

```csharp
// ✅ Use interfaces and abstractions
public interface IPaymentProcessor
{
    Task ProcessAsync(Payment payment);
}

public class CreditCardProcessor : IPaymentProcessor { }
public class PayPalProcessor : IPaymentProcessor { }
```

### Liskov Substitution Principle
Derived classes must be substitutable for their base classes.

### Interface Segregation Principle
Don't force clients to depend on methods they don't use.

```csharp
// ❌ Bad - Fat interface
public interface IRepository
{
    Task Add(); Task Update(); Task Delete();
    Task<List<T>> Search(); Task Export(); Task Import();
}

// ✅ Good - Segregated interfaces
public interface IWriteRepository { Task Add(); Task Update(); }
public interface IReadRepository { Task<T> GetById(); }
```

### Dependency Inversion Principle
Depend on abstractions, not concretions.

```csharp
// ✅ Controller depends on IMediator abstraction
public class OrdersController
{
    private readonly IMediator _mediator; // Abstraction

    public OrdersController(IMediator mediator) // Injected
    {
        _mediator = mediator;
    }
}
```

## Performance Standards

### API Response Times (95th percentile)
- Simple queries: < 100ms
- Complex queries: < 500ms
- Commands: < 1000ms

### Database Queries
- Avoid N+1 queries (use `.Include()` in EF)
- Use pagination for lists (max 100 items per page)
- Add indexes for frequently queried fields
- Use projections (select only needed columns)

```csharp
// ❌ Bad - N+1 query
var orders = await _context.Orders.ToListAsync();
foreach (var order in orders)
{
    var customer = await _context.Customers.FindAsync(order.CustomerId); // N queries
}

// ✅ Good - Single query with Include
var orders = await _context.Orders
    .Include(o => o.Customer)
    .ToListAsync();
```

## Security Standards

### Input Validation
- Validate ALL user input at Application layer
- Use FluentValidation for complex rules
- Sanitize input to prevent injection attacks

### Authentication & Authorization
- Use JWT tokens or cookies for authentication
- Implement role-based or policy-based authorization
- Check permissions before executing commands

```csharp
[Authorize(Roles = "Admin")]
[HttpDelete("{id}")]
public async Task<IActionResult> Delete(Guid id) { }
```

### Secrets Management
- NEVER commit secrets to source control
- Use environment variables or secret managers
- Rotate secrets regularly

## Error Handling

### Domain Layer
```csharp
// Throw domain exceptions for business rule violations
if (quantity <= 0)
    throw new DomainException("Quantity must be positive");
```

### Application Layer
```csharp
// Validate input, throw validation exceptions
var validationResult = await _validator.ValidateAsync(command);
if (!validationResult.IsValid)
    throw new ValidationException(validationResult.Errors);
```

### API Layer
```csharp
// Catch exceptions and return appropriate HTTP status codes
try
{
    await _mediator.Send(command);
    return Ok();
}
catch (NotFoundException ex)
{
    return NotFound(ex.Message);
}
catch (ValidationException ex)
{
    return BadRequest(ex.Errors);
}
catch (DomainException ex)
{
    return BadRequest(ex.Message);
}
```

## Documentation Standards

### Code Comments
- Document WHY, not WHAT
- Use XML comments for public APIs

```csharp
/// <summary>
/// Creates a new order for the specified customer.
/// Validates that customer exists and has sufficient credit.
/// </summary>
/// <param name="customerId">The customer's unique identifier</param>
/// <returns>The created order's ID</returns>
public async Task<Guid> CreateOrderAsync(Guid customerId) { }
```

### README Files
Each project/feature should have a README with:
- Purpose and overview
- Setup instructions
- Architecture decisions
- API documentation (if applicable)

## Git Practices

### Commit Messages
```
feat: Add order creation command and handler
fix: Correct validation for negative quantities
refactor: Extract order line creation to separate method
test: Add tests for order validation rules
docs: Update architecture guide with CQRS examples
```

### Branch Strategy
- `main` - Production-ready code
- `develop` - Integration branch
- `feature/*` - New features
- `fix/*` - Bug fixes

### Pull Requests
- Require code review before merge
- Must pass all tests
- Must meet 80% coverage requirement
- No merge conflicts

## Code Review Checklist

- [ ] Tests written and passing (>80% coverage)
- [ ] Follows Clean Architecture layers
- [ ] CQRS properly applied (Commands vs Queries)
- [ ] Input validated at Application layer
- [ ] Error handling implemented
- [ ] Follows naming conventions
- [ ] No hardcoded secrets
- [ ] Performance considered (no N+1 queries)
- [ ] Documentation updated if needed
- [ ] SOLID principles followed
