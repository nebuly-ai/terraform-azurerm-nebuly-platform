# Okta OICD Example

Nebuly supports several authentication methods. This example shows how to use [Okta OIDC](https://www.okta.com/openid-connect/) to authenticate users.

## Prerequisites

Before you begin, ensure you have an Okta account and access to the Okta Admin Console.

### Step 1: Create an Okta Application

1. **Log in to the Okta Admin Console**.
2. Navigate to the **Applications** menu and select **Create App Integration**.

3. In the **Sign-in method** section, choose **OIDC - OpenID Connect**.

4. For **Application type**, select **Web Application** and click **Next**.

5. Configure the application with the following settings:

   - **App Integration Name**: Enter a name for your app.
   - **Grant Type**: Choose **Authorization Code** and **Refresh Token**.
   - **Sign-In Redirect URIs**: Specify the following redirect URI, where `<platform_domain>` is the same value you provided
     for the Terraform variable `platform_domain`:
     ```
     https://<platform_domain>/backend/auth/oauth/okta/callback
     ```
   - **Sign-Out Redirect URIs**: Specify the following redirect URI, where `<platform_domain>` is the same value you provided
     for the Terraform variable `platform_domain`:
     ```
     http://<platform_domain>/logout
     ```
   - **Controlled Access**: Decide whether to assign the app integration to everyone in your organization or to specific groups. This can be adjusted after the app is created.

6. Take note of the **Client ID** and **Client Secret** values. You will need to provide these values as Terraform variables.

### Step 2: Configure Nebuly roles on Okta Application

1. In the **Okta Admin Console**, navigate to **Directory > Profile Editor**.

2. Locate and select the **Okta Application Profile** you created earlier (by default, this is named `<App name> User`).

3. Click **Add Attribute** and fill out the following fields:

   - **Data Type**: `string`
   - **Display Name**: `Nebuly Role`
   - **Variable Name**: `nebuly_role`
   - **Description** (optional): Include a description for the role. Example: `The role of the user in Nebuly Platform.`
   - **Enum**: Select **Define enumerated list of values** and add the following:
     - **Display Name**: `Admin` | **Value**: `admin`
     - **Display Name**: `Member` | **Value**: `member`
     - **Display Name**: `Viewer` | **Value**: `viewer`
   - The remaining fields are optional and can be configured as needed.

4. Click **Save**.

### Step 3: Assign the roles to users

1. In the **Okta Admin Console**, navigate to **Directory > People**.

2. Locate and select the user you want to assign a role to.

3. Click on **Assign Applications** and select the application you created in Step 1.

4. In the **Application Assignment** dialog, select the role you want to assign to the user. The role
   can be set using the field **Nebuly Role**, which is the last one in the list.

## Terraform configuration

To enable Okta OIDC authentication in Nebuly, you need to provide the following Terraform variables:

```hcl
okta_sso = {
    client_id     = "<client-id-from-step-1>"
    client_secret = "<client-secret-from-step-1>"
    issuer        = "https://<okta-tenant>.okta.com"
}
```
