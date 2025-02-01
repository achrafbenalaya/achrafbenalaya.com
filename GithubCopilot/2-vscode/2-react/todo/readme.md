# Project Structure and Launch Instructions

## Project Structure

The project consists of the following main components:

- **src/**: This directory contains the source code of the project.
    - **main/**: Contains the main application code.
        - **App.java**: The main entry point of the application.
        - **controllers/**: Contains the controller classes responsible for handling user input and interactions.
        - **models/**: Contains the model classes representing the data and business logic.
        - **views/**: Contains the view classes responsible for rendering the user interface.
    - **test/**: Contains the test code for the application.
        - **AppTest.java**: Contains unit tests for the main application code.

- **resources/**: This directory contains the resource files such as configuration files, templates, and static assets.
    - **application.properties**: Configuration file for the application.
    - **templates/**: Contains HTML templates for rendering views.
    - **static/**: Contains static assets like CSS, JavaScript, and images.

- **build.gradle**: The Gradle build file used to manage project dependencies and build configuration.

## How It Works

1. **App.java**: The main entry point of the application. It initializes the application context and starts the server.
2. **Controllers**: Handle user input and interactions. They process requests, interact with the model, and return appropriate responses.
3. **Models**: Represent the data and business logic of the application. They interact with the database and perform necessary operations.
4. **Views**: Render the user interface. They use templates to generate HTML pages that are sent to the client.

## How to Launch

1. **Install Dependencies**: Ensure you have Java and Gradle installed on your system.
2. **Build the Project**: Navigate to the project directory and run the following command to build the project:
     ```sh
     gradle build
     ```
3. **Run the Application**: After the build is successful, run the following command to start the application:
     ```sh
     gradle run
     ```
4. **Access the Application**: Open a web browser and navigate to `http://localhost:8080` to access the application.
