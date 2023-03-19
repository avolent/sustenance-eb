import base64
import hashlib
import hmac
import logging
import os
from typing import Union

import boto3
from botocore.exceptions import ClientError

LOGGER = logging.getLogger(__name__)
COGNITO_CLIENT = boto3.client("cognito-idp", region_name=os.getenv("AWS_REGION"))
COGNITO_USER_POOL_ID = os.getenv("COGNITO_USER_POOL_ID")
COGNITO_APP_CLIENT_ID = os.getenv("COGNITO_APP_CLIENT_ID")
COGNITO_APP_CLIENT_SECRET = os.getenv("COGNITO_APP_CLIENT_SECRET")

class CognitoIdentityProviderWrapper:
    """Encapsulates Amazon Cognito actions"""

    def __init__(self):
        """
        :param cognito_idp_client: A Boto3 Amazon Cognito Identity Provider client.
        :param user_pool_id: The ID of an existing Amazon Cognito user pool.
        :param client_id: The ID of a client application registered with the user pool.
        :param client_secret: The client secret, if the client has a secret.
        """
        self.cognito_idp_client = COGNITO_CLIENT
        self.user_pool_id = COGNITO_USER_POOL_ID
        self.client_id = COGNITO_APP_CLIENT_ID
        self.client_secret = COGNITO_APP_CLIENT_SECRET

    def _secret_hash(self, username: str) -> bytes:
        """
        Calculates a secret hash from a user name and a client secret.
        :param username: The user name to use when calculating the hash.
        :return: The secret hash.
        """
        key = self.client_secret.encode()
        msg = bytes(username + self.client_id, 'utf-8')
        secret_hash = base64.b64encode(
            hmac.new(key, msg, digestmod=hashlib.sha256).digest()).decode()
        LOGGER.info("Made secret hash for %s: %s.", username, secret_hash)
        return secret_hash

    def sign_up_user(self, username: str, password: str) -> Union[str, Exception]:
        """
        Signs up a new user with Amazon Cognito. This action prompts Amazon Cognito
        to send an email to the specified email address. The email contains a code that
        can be used to confirm the user.
        When the user already exists, the user status is checked to determine whether
        the user has been confirmed.
        :param username: The user name that identifies the new user.
        :param password: The password for the new user.
        :param email: The email address for the new user.
        :return: True when the user is already confirmed with Amazon Cognito.
                 Otherwise, false.
        """
        try:
            kwargs = {
                'ClientId': self.client_id, 'Username': username, 'Password': password,
                'UserAttributes': [{'Name': 'email', 'Value': username}]}
            if self.client_secret is not None:
                kwargs['SecretHash'] = self._secret_hash(username)
            response = self.cognito_idp_client.sign_up(**kwargs)
            return response
        except ClientError as err:
            if err.response['Error']['Code'] == 'UsernameExistsException':
                response = self.cognito_idp_client.admin_get_user(
                    UserPoolId=self.user_pool_id, Username=username)
                LOGGER.warning(f"User {username} exists and is {response['UserStatus']}.")
                return Exception(f"User {username} exists and is {response['UserStatus']}.")
            else:
                LOGGER.error(f"Couldn't sign up {username}. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Code']}")
                return Exception(f"Couldn't sign up {username}. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Code']}")

    def resend_confirmation(self, username: str) -> Union[str, Exception]:
        """
        Prompts Amazon Cognito to resend an email with a new confirmation code.
        :param username: The name of the user who will receive the email.
        :return: Delivery information about where the email is sent.
        """
        try:
            kwargs = {
                'ClientId': self.client_id, 'Username': username}
            response = self.cognito_idp_client.admin_get_user(
                    UserPoolId=self.user_pool_id, Username=username)
            if self.client_secret is not None:
                kwargs['SecretHash'] = self._secret_hash(username)
            response = self.cognito_idp_client.resend_confirmation_code(
                **kwargs)
            return response
        except ClientError as err:
            LOGGER.error(f"Couldn't resend confirmation to {username}. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")
            return Exception(f"Couldn't resend confirmation to {username}. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")

    def confirm_user_sign_up(self, username: str, confirmation_code: str) -> Union[str, Exception]:
        """
        Confirms a previously created user. A user must be confirmed before they
        can sign in to Amazon Cognito.
        :param username: The name of the user to confirm.
        :param confirmation_code: The confirmation code sent to the user's registered
                                  email address.
        :return: True when the confirmation succeeds.
        """
        try:
            kwargs = {
                'ClientId': self.client_id, 'Username': username,
                'ConfirmationCode': confirmation_code}
            if self.client_secret is not None:
                kwargs['SecretHash'] = self._secret_hash(username)
            response = self.cognito_idp_client.confirm_sign_up(**kwargs)
            return response
        except ClientError as err:
            LOGGER.error(f"Couldn't confirm sign up for {username}. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")
            return Exception(f"Couldn't confirm sign up for {username}. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")
        
    def sign_in(self, username: str, password: str) -> Union[str, Exception]:
        """
        To be filled
        :param username: The name of the user to confirm.
        :param confirmation_code: The confirmation code sent to the user's registered
                                  email address.
        :return: True when the confirmation succeeds.
        """
        try:
            kwargs = {
                'UserPoolId': self.user_pool_id,
                'ClientId': self.client_id,
                'AuthFlow': 'ADMIN_USER_PASSWORD_AUTH',
                'AuthParameters': {'USERNAME': username, 'PASSWORD': password}}
            if self.client_secret is not None:
                kwargs['AuthParameters']['SECRET_HASH'] = self._secret_hash(username)
            response = self.cognito_idp_client.admin_initiate_auth(**kwargs)
            return response
        except ClientError as err:
            LOGGER.error(f"Couldn't sign in for {username}. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")
            return Exception(f"Couldn't sign in for {username}. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")

    def sign_out(self, username: str) -> Union[str, Exception]:
        """
        To be filled
        :param username: The name of the user to confirm.
        :param confirmation_code: The confirmation code sent to the user's registered
                                  email address.
        :return: True when the confirmation succeeds.
        """
        try:
            kwargs = {
                'UserPoolId': self.user_pool_id,
                'Username': username,
            }
            response = self.cognito_idp_client.admin_user_global_sign_out(**kwargs)
            return response
        except ClientError as err:
            LOGGER.error(f"Couldn't sign in for {username}. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")
            return Exception(f"Couldn't sign in for {username}. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")


    def get_user(self, username: str):
        """
        To be filled.
        """
        try:
            kwargs = {
                'UserPoolId': self.user_pool_id,
                'Username': username,
            }
            response = self.cognito_idp_client.admin_get_user(**kwargs)
            return response
        except ClientError as err:
            LOGGER.error(f"Couldn't retrieve {username} details. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")
            return Exception(f"Couldn't retrieve {username} details. Here's why: {err.response['Error']['Code']}: {err.response['Error']['Message']}")
