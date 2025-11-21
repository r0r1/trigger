# PR Collector

A Ruby on Rails application that collects and displays Pull Requests and Merge Requests from GitHub, GitLab, and Bitbucket. This application is designed to work with the Model Context Protocol (MCP) concept by acting as a client that aggregates data from multiple repository providers.

## Features

- **Multi-Provider Authentication**: Sign in with Google, GitHub, or Bitbucket.
- **Unified Dashboard**: View all your open PRs and MRs in one place.
- **Secure Token Storage**: Encrypted storage for Personal Access Tokens (PATs).
- **MCP Integration**: Connects to repository providers via their APIs using user-configured credentials.

## Tech Stack

- **Framework**: Ruby on Rails 8 (Stable)
- **Styling**: Tailwind CSS
- **Database**: PostgreSQL
- **Authentication**: Devise + OmniAuth

## Setup

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd sonic-event
    ```

2.  **Install dependencies**:
    ```bash
    bundle install
    ```

3.  **Setup Database**:
    ```bash
    rails db:setup
    ```

4.  **Environment Variables**:
    Create a `.env` file in the root directory (or export these variables) with your OAuth credentials:

    ```bash
    # Google
    GOOGLE_CLIENT_ID=your_google_client_id
    GOOGLE_CLIENT_SECRET=your_google_client_secret

    # GitHub
    GITHUB_CLIENT_ID=your_github_client_id
    GITHUB_CLIENT_SECRET=your_github_client_secret

    # Bitbucket
    BITBUCKET_CLIENT_ID=your_bitbucket_client_id
    BITBUCKET_CLIENT_SECRET=your_bitbucket_client_secret
    ```

5.  **Run the server**:
    ```bash
    rails s
    ```

## Usage

1.  **Login**: Use one of the social login options on the home page.
2.  **Configure Connections**: Go to **Settings** and enter your Personal Access Tokens for the providers you want to fetch data from.
    *   **GitHub**: Generate a PAT with `repo` scope.
    *   **GitLab**: Generate a PAT with `read_api` scope.
    *   **Bitbucket**: Generate an App Password or PAT with `pullrequest:read` scope.
3.  **View Dashboard**: Navigate to the **Dashboard** to see your active Pull Requests.

## Callback URIs

When configuring your OAuth apps, use the following Redirect URIs (replace `localhost:3000` with your production domain if deploying):

- **Google**: `http://localhost:3000/users/auth/google_oauth2/callback`
- **GitHub**: `http://localhost:3000/users/auth/github/callback`
- **Bitbucket**: `http://localhost:3000/users/auth/bitbucket/callback`
