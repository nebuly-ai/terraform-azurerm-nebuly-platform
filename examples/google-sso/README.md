# Google OAuth Example

Nebuly supports several authentication methods. This example shows how to use [Google OAuth 2.0](https://developers.google.com/identity/protocols/oauth2) to authenticate users.

## Prerequisites

Before you begin, ensure you have a Google Cloud Platform account and access to the Google Cloud Console.

### Step 1: Create a Google OAuth Application

1. **Log in to the Google Cloud Console**.
2. Navigate to the **APIs & Services** menu and select **Credentials**.

3. Click on **Create Credentials** and select **OAuth client ID**.

4. If prompted, configure the OAuth consent screen:

   - Select internal user type
   - Enter the required information (App name, user support email, etc.)
   - Add the following scopes: (email, profile, openid)
   - Add authorized domains and save

5. For **Application type**, select **Web application** and provide a name.

6. Configure the application with the following settings:

   - **Authorized JavaScript origins**: Enter your platform domain, where `<platform_domain>` is the same value you provided
     for the Terraform variable `platform_domain`:
     ```
     https://<platform_domain>
     ```
   - **Authorized redirect URIs**: Specify the following redirect URI, where `<platform_domain>` is the same value you provided
     for the Terraform variable `platform_domain`:
     ```
     https://<platform_domain>/backend/auth/oauth/google/callback
     ```

7. Click **Create** and take note of the **Client ID** and **Client Secret** values. You will need to provide these values as Terraform variables.

### Step 2: Enable Cloud Identity API

Visit https://console.cloud.google.com/apis/api/cloudidentity.googleapis.com/ and press "Enable" if Cloud Identity has not been enabled yet for your organization.

### Step 3: Configure role groups for Google users

Google OAuth integration with Nebuly uses Google Groups to determine user roles. You'll need to create or use existing Google Groups for different access levels.

1. In the **Google Admin Console**, navigate to **Directory > Groups**.

2. Create or identify groups for different Nebuly roles:

   - A group for administrators (e.g., `nebuly-admins@yourdomain.com`)
   - A group for regular members (e.g., `nebuly-members@yourdomain.com`)
   - A group for viewers (e.g., `nebuly-viewers@yourdomain.com`)

3. Add users to these groups according to the access level they should have in Nebuly.

### Step 4: Map Google Groups to Nebuly roles

Nebuly maps Google Groups to roles based on email domains or specific group addresses. You'll configure this mapping in your Terraform configuration.

## Terraform configuration

To enable Google OAuth authentication in Nebuly, you need to provide the following Terraform variables:

```hcl
google_sso = {
    client_id       = "<client-id-from-step-1>"
    client_secret   = "<client-secret-from-step-1>"
    role_mapping    =  {
      "viewer" = "<viewer-group-email>"
      "member" = "<member-group-email>"
      "admin"  = "<admin-group-email>"
    }
}
```
