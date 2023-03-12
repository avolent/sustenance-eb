import boto3
from botocore.exceptions import ClientError
from cognito import CognitoIdentityProviderWrapper
from flask import ( 
    Flask,
    render_template,
    request,
    redirect
)
import os
import secrets

app = Flask(__name__)
app.config.update(
    PREFERRED_URL_SCHEME="https",
    SECRET_KEY=secrets.token_hex(32),
    SESSION_COOKIE_SECURE=True,
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
)

COGNITO_REGION = os.getenv("COGNITO_REGION")
USER_POOL_ID = os.getenv("COGNITO_USER_POOL_ID")
APP_CLIENT_ID = os.getenv("COGNITO_APP_CLIENT_ID")
# IDENTITY_POOL_ID = os.getenv("COGNITO_IDENTIY_POOL_ID")

cognito = CognitoIdentityProviderWrapper(
    cognito_idp_client=boto3.client("cognito-idp", region_name=COGNITO_REGION),
    client_id=APP_CLIENT_ID,
    user_pool_id=USER_POOL_ID,
)


# cognito_identity = boto3.client("cognito-identity", region_name=COGNITO_REGION)

@app.route("/")
def home():
    return render_template("index.html")


@app.route("/register", methods=["POST"])
def register():
    try:
        response = cognito.sign_up_user(
            
        )
        return response
    except Exception as error:
        return error
    

if __name__ == "__main__":
    app.run()
