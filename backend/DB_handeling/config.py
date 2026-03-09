from dotenv import load_dotenv
import os

# Load all variables from the .env file
load_dotenv()

# Read the database URL directly from .env
DATABASE_URL = os.getenv("DATABASE_URL")