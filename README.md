You can add the additional installation steps and system requirements information to your README.md as follows:

```markdown
# Gab App

Welcome to Gab App! This is a Laravel-based e-commerce application built to simplify online shopping experiences. It offers a range of features to manage products, orders, customers, and more.

## Features

- **Product Management:** Easily add, edit, and delete products with comprehensive management tools.
- **Order Tracking:** Keep track of orders and their statuses for efficient order management.
- **Customer Management:** Manage customer accounts and track their activities on the platform.
- **Secure Transactions:** Ensure secure transactions with built-in security features.
- **Customization:** Customize the platform to fit your business needs with flexible configuration options.

## Installation

To get started with Gab App, follow these steps:

1. Clone the repository:

   ```bash
   git clone https://github.com/kaspernux/gab-app.git
   ```

2. Set permissions:

   ```bash
   cd gab-app && chmod +x gab-app/install.sh
   ```

3. Adjust your Apache, MySQL, and PHPMyAdmin port by modifying the docker-compose.yml file.

4. Run the setup script:

   ```bash
   sh gab-app/setup.sh
   ```

5. After the installation, you can access the admin panel at:

   [http://your_server_endpoint/admin/login](http://your_server_endpoint/admin/login)

   - Email: admin@example.com
   - Password: admin123

   To log in as a customer, you can directly register as a customer and then login at:

   [http://your_server_endpoint/customer/register](http://your_server_endpoint/customer/register)

## System Requirements

The system/server requirements for Gab App are fulfilled by Docker containers. Make sure you have the latest version of Docker and Docker Compose installed. Docker supports Linux, MacOS, and Windows Operating System. You can find their installation guides here:

- [Docker Installation Guide](https://docs.docker.com/get-docker/)
- [Docker Compose Installation Guide](https://docs.docker.com/compose/install/)

## Contributing

Contributions are welcome! If you'd like to contribute to Gab App, please follow these guidelines:

- Fork the repository
- Create a new branch (`git checkout -b feature/my-feature`)
- Commit your changes (`git commit -am 'Add new feature'`)
- Push to the branch (`git push origin feature/my-feature`)
- Create a new Pull Request

## License

This project is licensed under the [MIT License](LICENSE).
```

You can replace "your_server_endpoint" with the actual URL where your application will be hosted. Make sure to replace placeholders like email and password with the actual credentials used in your application.
