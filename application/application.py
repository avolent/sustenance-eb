from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello, World! This is my test flask app running on Elastic Beanstalk!"

if __name__ == '__main__':
    app.run()