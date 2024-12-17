from firebase_functions import https_fn
from firebase_admin import initialize_app
import requests

# Inicializa o Firebase Admin SDK
initialize_app()

# Middleware para habilitar CORS
def allow_cors(response):
    response.headers["Access-Control-Allow-Origin"] = "*"  # Permite todas as origens
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    return response

SPOTIFY_API_URL = "https://api.spotify.com/v1"

# Função para obter o Access Token usando Client ID e Client Secret
def get_access_token(client_id: str, client_secret: str):
    url = "https://accounts.spotify.com/api/token"
    headers = {
        "Content-Type": "application/x-www-form-urlencoded"
    }
    data = {
        "grant_type": "client_credentials"
    }
    # Definindo o client_id e client_secret como autenticação básica
    auth = (client_id, client_secret)
    
    # Fazendo a requisição para obter o token
    response = requests.post(url, headers=headers, data=data, auth=auth)
    
    # Verificando se a requisição foi bem-sucedida
    if response.status_code == 200:
        return response.json()["access_token"]
    else:
        raise Exception("Erro ao obter o Access Token: " + response.text)

# Função principal que busca dados do Spotify
@https_fn.on_request()
def get_spotify_data(req: https_fn.Request) -> https_fn.Response:
    # Tratar métodos OPTIONS para CORS
    if req.method == "OPTIONS":
        return allow_cors(https_fn.Response("OK", status=204))

    # Defina seu Client ID e Client Secret do Spotify
    client_id = "4c4da1c7a8874e4996356c1792886893"
    client_secret = "5bdb986fb7bc4bf2ba8b0edb6c135779"

    # Obter o Access Token
    try:
        access_token = get_access_token(client_id, client_secret)
    except Exception as e:
        return allow_cors(https_fn.Response(str(e), status=500))
    
    # Fazer requisição à API do Spotify
    headers = {"Authorization": f"Bearer {access_token}"}
    response = requests.get(f"{SPOTIFY_API_URL}/search?q=Calvin%20Harris&type=track", headers=headers)

    # Retornar a resposta da API do Spotify
    if response.status_code == 200:
        return allow_cors(https_fn.Response(response.text, status=200))
    else:
        return allow_cors(https_fn.Response(response.text, status=response.status_code))
