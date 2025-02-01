# Project Overview

This project is a Go application designed to connect to a PostgreSQL database and retrieve user information. The application demonstrates how to use the `database/sql` package along with the PostgreSQL driver `github.com/lib/pq` to perform database operations.

## Features

- Connects to a PostgreSQL database using a connection string.
- Retrieves user information based on a user ID.
- Handles errors gracefully, including cases where the user is not found.

## How It Works

1. The application reads the database connection string from the `DATABASE_URL` environment variable.
2. It establishes a connection to the PostgreSQL database.
3. It queries the database for a user with a specified ID.
4. It prints the retrieved user information to the console.

This project serves as a basic example of database interaction in Go, showcasing best practices for error handling and environment variable usage.