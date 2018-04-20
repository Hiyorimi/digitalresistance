module.exports = {
  root: true,
  parser: 'babel-eslint',
  'extends': [
    'airbnb',
    'prettier',
  ],
  plugins: [
    'prettier'
  ],
  env: {
    browser: true,
    node: true,
    es6: true,
  },
  parserOptions: {
    ecmaVersion: 7,
    sourceType: 'module',
  },
  rules: {
    'no-underscore-dangle': 0,
    'no-console': 0,
    'no-await-in-loop': 0,
    'prettier/prettier': [
      'error',
      {
        singleQuote: true,
        printWidth: 70,
        trailingComma: 'es5',
        semi: false,
      }
    ],
  }
}
