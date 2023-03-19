import secrets
import logging

from flask import ( 
    Flask,
    session,
    render_template,
    request,
    redirect,
    url_for,
    make_response
)

from flask_login import (
    LoginManager,
    current_user,
    login_user,
    login_required,
    logout_user
)
from drivers.cognito import CognitoIdentityProviderWrapper
from entities.user import User
from entities.forms import RegistrationForm, LoginForm, ConfirmationForm, ResendConfirmation

app = Flask(__name__)
app.config.update(
    PREFERRED_URL_SCHEME="https",
    SECRET_KEY=secrets.token_hex(32),
    SESSION_COOKIE_SECURE=True,
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
)

COGNITO = CognitoIdentityProviderWrapper()
LOGGER = logging.getLogger(__name__)

login_manager = LoginManager()
login_manager.init_app(app)



@login_manager.user_loader
def load_user(user_id):
    response = COGNITO.get_user(
        username=user_id
    )
    if isinstance(response, Exception):
        LOGGER.error(f"User loader failed to retrieve details for {user_id}", exception=str(response))
        return None
    return User(user_id, True)


@app.route("/")
def index():
    return render_template("index.html")

@app.route('/dashboard')
@login_required
def dashboard():
    return render_template("dashboard.html")


@app.route("/login", methods=["GET", "POST"])
def login():
    form = LoginForm()
    if request.method == "POST":
        if form.validate_on_submit():
            response = COGNITO.sign_in(
                username=request.form.get("email"),
                password=request.form.get("password")
            )
            if isinstance(response, Exception):
                return render_template("confirmation.html", confirmation_form=ConfirmationForm(), resend_form=ResendConfirmation())
            session['access_token'] = response['AuthenticationResult']['AccessToken']
            session['refresh_token'] = response['AuthenticationResult']['RefreshToken']
            login_user(User(request.form.get("email"), True))
            return redirect(url_for("dashboard"))
    return render_template("login.html", form=form)


@app.route("/register", methods=["GET", "POST"])
def register():
    form = RegistrationForm()
    if request.method == "POST":
        if form.validate_on_submit():
            response = COGNITO.sign_up_user(
                username=request.form.get("email"),
                password=request.form.get("password"),
            )
            if isinstance(response, Exception):
                return str(response)
            return render_template("confirmation.html", confirmation_form=ConfirmationForm(), resend_form=ResendConfirmation())
    return render_template("register.html", form=form)
    
    
@app.route("/confirm", methods=["POST"])
def confirm():
    if request.form.get("resend"):
        response = COGNITO.resend_confirmation(
            username=request.form.get("email")
        )
        if isinstance(response, Exception):
            return str(response)
        response = make_response('')
        response.status_code = 204
        return response
    response = COGNITO.confirm_user_sign_up(
        username=request.form.get("email"),
        confirmation_code=request.form.get("code")
    )
    if isinstance(response, Exception):
        return render_template("confirmation.html", confirmation_form=ConfirmationForm(), resend_form=ResendConfirmation())
    return render_template("login.html", form=LoginForm())
    

@app.route("/logout", methods=["GET"])
@login_required
def logout():
    response = COGNITO.sign_out(
        username=current_user.id
    )
    if isinstance(response, Exception):
        return str(response)
    logout_user()
    return redirect(url_for("index"))
    

if __name__ == "__main__":
    app.run()
