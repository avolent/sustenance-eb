import re
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, BooleanField
from wtforms.validators import DataRequired, Email, EqualTo, Length

class RegistrationForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired(), Length(min=8)])
    confirm_password = PasswordField('Confirm Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Sign Up')


class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired(), Length(min=8)])
    remember = BooleanField('Remember Me')
    submit = SubmitField('Log In')


class ConfirmationForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    code = StringField('Confirmation Code', validators=[])
    submit = SubmitField('Confirm')
    resend = SubmitField("Resend Confirmation")

class ResendConfirmation(FlaskForm):
    resend = SubmitField("Resend Confirmation")