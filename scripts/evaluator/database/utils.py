def get_connection_string(database_name: str) -> str:
    host = os.getenv('DB_HOST', 'localhost')
    port = os.getenv('DB_PORT', '5432')
    user = os.getenv('DB_USER', 'postgres')
    password = os.getenv('DB_PASSWORD', 'postgres')
    return f"postgresql://{user}:{password}@{host}:{port}/{database_name}"w