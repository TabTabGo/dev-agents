#!/bin/bash

# GitHub Copilot Setup Script
# Copies Copilot instructions to target project

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if target path is provided
if [ -z "$1" ]; then
    TARGET_PATH="."
    echo -e "${YELLOW}No target path provided, using current directory${NC}"
else
    TARGET_PATH="$1"
fi

# Validate target path exists
if [ ! -d "$TARGET_PATH" ]; then
    echo -e "${RED}Error: Target path does not exist: $TARGET_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}Setting up GitHub Copilot configuration...${NC}"
echo "Target: $TARGET_PATH"

# Create .github directory if it doesn't exist
GITHUB_DIR="$TARGET_PATH/.github"
mkdir -p "$GITHUB_DIR"

# Copy or create copilot-instructions.md
COPILOT_FILE="$GITHUB_DIR/copilot-instructions.md"

if [ -f ".github/copilot-instructions.md" ]; then
    echo -e "${YELLOW}Copying copilot-instructions.md...${NC}"
    cp .github/copilot-instructions.md "$COPILOT_FILE"
    echo "  ✓ Copilot instructions copied"
else
    # Create default copilot-instructions.md
    echo -e "${YELLOW}Creating default copilot-instructions.md...${NC}"
    cat > "$COPILOT_FILE" << 'EOF'
# GitHub Copilot Instructions

## Architecture Standards

This project follows Clean Architecture with CQRS patterns:

### Layer Structure
1. **Domain** - Business logic and entities (no dependencies)
2. **Application** - Use cases with Commands and Queries (MediatR)
3. **Infrastructure** - Data access and external services
4. **API/Presentation** - Controllers and UI

### CQRS with MediatR
- **Commands** modify state, return void or ID
- **Queries** read data, no side effects
- Use FluentValidation for all commands

### Code Quality
- Write tests BEFORE implementation (TDD)
- Minimum 80% code coverage required
- Follow SOLID principles
- Use dependency injection

## Templates

### Command Handler
```csharp
public record CreateEntityCommand(string Name) : IRequest<Guid>;

public class CreateEntityCommandHandler : IRequestHandler<CreateEntityCommand, Guid>
{
    private readonly IRepository<Entity> _repository;

    public async Task<Guid> Handle(CreateEntityCommand request, CancellationToken ct)
    {
        var entity = Entity.Create(request.Name);
        await _repository.AddAsync(entity, ct);
        return entity.Id;
    }
}
```

### Query Handler
```csharp
public record GetEntityQuery(Guid Id) : IRequest<EntityDto>;

public class GetEntityQueryHandler : IRequestHandler<GetEntityQuery, EntityDto>
{
    private readonly IReadRepository<Entity> _repository;

    public async Task<EntityDto> Handle(GetEntityQuery request, CancellationToken ct)
    {
        var entity = await _repository.GetByIdAsync(request.Id, ct);
        return entity.ToDto();
    }
}
```

## Guidelines

When generating code:
1. Follow Clean Architecture layer boundaries
2. Separate Commands (write) from Queries (read)
3. Validate input at Application layer
4. Write unit tests alongside code
5. Use async/await with CancellationToken
6. Return DTOs from API, not domain entities
7. Handle errors appropriately per layer
EOF
    echo "  ✓ Default copilot-instructions.md created"
fi

# Copy prompts if they exist
if [ -d "prompts" ] && [ "$(ls -A prompts 2>/dev/null)" ]; then
    echo -e "${YELLOW}Copying prompt templates...${NC}"
    PROMPTS_DIR="$GITHUB_DIR/copilot-prompts"
    mkdir -p "$PROMPTS_DIR"
    cp -r prompts/* "$PROMPTS_DIR/"
    echo "  ✓ Prompts copied to $PROMPTS_DIR/"
fi

# Copy shared patterns as reference (optional)
echo -e "${YELLOW}Would you like to copy shared patterns for reference? (y/n)${NC}"
read -r COPY_PATTERNS

if [ "$COPY_PATTERNS" = "y" ] || [ "$COPY_PATTERNS" = "Y" ]; then
    PATTERNS_DIR="$GITHUB_DIR/dev-patterns"
    mkdir -p "$PATTERNS_DIR"
    cp -r ../../shared/patterns/* "$PATTERNS_DIR/"
    echo "  ✓ Patterns copied to $PATTERNS_DIR/"
fi

echo -e "${GREEN}✓ GitHub Copilot setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Open your project in VS Code"
echo "  2. Use @workspace in Copilot Chat to reference these instructions"
echo "  3. Copilot will automatically follow the patterns defined in:"
echo "     $COPILOT_FILE"
echo ""
echo "Tips:"
echo "  - Ask Copilot: '@workspace create a new command for X'"
echo "  - Ask Copilot: '@workspace what's the CQRS pattern here?'"
echo "  - Ask Copilot: '@workspace write tests for this handler'"
