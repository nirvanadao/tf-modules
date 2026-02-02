# Claude Development Guidelines

## Terraform Validation

After every logical change to Terraform modules, you MUST run the validation script:

```bash
./scripts/validate-all.sh
```

This script validates all Terraform modules in the repository to ensure:
- Proper formatting
- Valid syntax
- No configuration errors
- All modules can be initialized successfully

**Important**: Do not consider a Terraform change complete until this validation passes.
