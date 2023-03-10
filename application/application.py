from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return "Hello, World! This is my test flask app running on Elastic Beanstalk!"

@app.route('/health')
def health():
    return "Healthy"

if __name__ == '__main__':
    app.run()