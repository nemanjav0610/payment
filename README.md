# Payment Backend

A distributed payment processing system built with Elixir and Phoenix, using ArangoDB as the database.

## Overview

This is an umbrella project consisting of three main applications:

- **payment**: Core payment processing logic
- **payment_web**: Phoenix web interface and API endpoints
- **arango**: Database interface and schemas

## Prerequisites

- Elixir 1.13+
- ArangoDB 3.x
- Node.js (for asset compilation)

## Installation

1. Clone the repository
2. Install dependencies:
```bash
mix deps.get
cd apps/payment_web/assets && npm install
```

3. Configure your database settings in `config/dev.exs`:

```elixir
config :payment, Payment.Repo,
  database: "your_database",
  username: "your_username",
  password: "your_password",
  endpoints: ["your_arango_endpoint"],
  show_sensitive_data_on_connection_error: false,
  pool_size: 10
```

## Running the Application

Start the Phoenix server:

```bash
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) from your browser.

## Project Structure

- `/apps/payment` - Core payment processing logic
- `/apps/payment_web` - Web interface and API endpoints
- `/apps/arango` - Database interface and schemas
- `/config` - Application configuration
- `/dockerfiles` - Docker configuration

## Features

- Payment processing
- Transaction management
- Invoice handling
- Multiple payment gateway support
- Real-time updates via Phoenix channels
- REST API endpoints
- CORS support for client applications

## Configuration

### Development
Configuration for development environment can be found in `config/dev.exs`

### Production
Production configuration uses environment variables for sensitive data:

- `SECRET_KEY_BASE` - Required for production deployment
- `CLIENTS_DOMAIN` - Comma-separated list of allowed CORS origins
- `PORT` - Server port (defaults to 4000)

## Docker Deployment

A Dockerfile is provided for containerized deployment. Build and run with:

```bash
docker build -f dockerfiles/Dockerfile -t payment-backend .
docker run -p 4000:4000 payment-backend
```

## Database

The application uses ArangoDB with the following collections:
- invoices
- transactions
- payment_gateways
- transactions_history

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Elixir](https://elixir-lang.org/)
- [ArangoDB](https://www.arangodb.com/)
