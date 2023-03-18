import secrets

from flask import ( 
    Flask,
    render_template,
    request,
)
from flask_wtf.csrf import CSRFProtect

from .drivers.cognito import CognitoIdentityProviderWrapper

app = Flask(__name__)
app.config.update(
    PREFERRED_URL_SCHEME="https",
    SECRET_KEY=secrets.token_hex(32),
    SESSION_COOKIE_SECURE=True,
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
)
csrf = CSRFProtect(app)

COGNITO = CognitoIdentityProviderWrapper()


@app.route("/")
def home():
    return render_template("index.html")


@app.route("/user")
def user():
    return render_template("login.html")


@app.route("/register", methods=["POST"])
def register():
    response = COGNITO.sign_up_user(
        user_name=request.form.get("email"),
        user_email=request.form.get("email"),
        password=request.form.get("password"),
    )
    if isinstance(response, Exception):
        return str(response)
    return response


@app.route("/login", methods=["POST"])
def login():
    response = COGNITO.sign_in(
        user_name=request.form.get("email"),
        password=request.form.get("password")
    )
    if isinstance(response, Exception):
        return str(response)
    return response
    

@app.route("/confirm", methods=["POST"])
def confirm():
    response = COGNITO.confirm_user_sign_up(
        user_name=request.form.get("email"),
        confirmation_code=request.form.get("confirmation")
    )
    if isinstance(response, Exception):
        return str(response)
    return response
    
    
@app.route("/confirmation_code", methods=["POST"])
def confirmation_code():
    response = COGNITO.resend_confirmation(
        user_name=request.form.get("email")
    )
    if isinstance(response, Exception):
        return str(response)
    return response
    

if __name__ == "__main__":
    app.run()
