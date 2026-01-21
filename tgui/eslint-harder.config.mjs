import existingConfig from './eslint.config.mjs';
import { defineConfig } from 'eslint/config';

export default defineConfig([
  {
    extends: [existingConfig],
    rules: {
      'no-unreachable-loop': 'warn',
      'sonar/max-switch-cases': 'warn',
      'sonar/no-all-duplicated-branches': 'warn',
      'sonar/no-collapsible-if': 'warn',
      'sonar/no-collection-size-mischeck': 'warn',
      'sonar/no-duplicated-branches': 'warn',
      'sonar/no-element-overwrite': 'warn',
      'sonar/no-extra-arguments': 'warn',
      'sonar/no-identical-conditions': 'warn',
      'sonar/no-identical-expressions': 'warn',
      'sonar/no-identical-functions': 'warn',
      'sonar/no-inverted-boolean-check': 'warn',
      'sonar/no-redundant-boolean': 'warn',
      'sonar/no-redundant-jump': 'warn',
      'sonar/no-same-line-conditional': 'warn',
      'sonar/no-small-switch': 'warn',
      'sonar/no-unused-collection': 'warn',
      'sonar/no-use-of-empty-return-value': 'warn',
      'sonar/no-useless-catch': 'warn',
      'sonar/prefer-immediate-return': 'warn',
      'sonar/prefer-object-literal': 'warn',
      'sonar/prefer-single-boolean-return': 'warn',
      'sonar/prefer-while': 'warn',
    },
  },
]);
