name: Build and Deploy

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Set up Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '14'

    - name: Install dependencies
      run: npm install

    - name: Create project structure
      run: |
        chmod +x gab-app/scripts/create_structure.sh
        ./gab-app/scripts/create_structure.sh

    - name: Run setup script
      run: |
        chmod +x gab-app/scripts/setup.sh
        ./gab-app/scripts/setup.sh
