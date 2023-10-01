from flask import Flask, request, render_template, render_template_string
import logging 

app = Flask(__name__)
app.debug=True
logging.basicConfig(filename='app.log', level=logging.DEBUG, format='%(asctime)s PYTHON_APP: %(levelname)s-%(message)s')

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == "POST":
        raw = request.form["input"]
        logging.info(f"POSTED_DATAS : {raw}")
        data = render_template_string(raw)
        logging.info(f"RETURNED_DATAS : {data}")
        return render_template("index.html", data=data)
    return render_template("index.html")

if __name__ == "__main__":
	app.run(host="0.0.0.0", port="4444")