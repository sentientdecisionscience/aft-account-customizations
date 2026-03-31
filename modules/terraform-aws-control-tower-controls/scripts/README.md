Here are the step-by-step instructions to create and activate a Python virtual environment:

- For macOS/Linux:

```
# Create the virtual environment
python3 -m venv venv

# Activate the virtual environment
source venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

- For Windows:

```
# Create the virtual environment
python -m venv venv

# Activate the virtual environment
venv\Scripts\activate

# Install requirements
pip install -r requirements.txt
```

To deactivate the virtual environment (same for all platforms):

```
deactivate
```
