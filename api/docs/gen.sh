#!/bin/bash

cd "$(dirname "$0")/.." || exit 1
swag init -g main.go -o docs --parseDependency --parseInternal --outputTypes json
