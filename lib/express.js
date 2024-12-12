const express = require('express');
const axios = require('axios');
const querystring = require('querystring');

const app = express();
const PORT = 3000;

// Este é o seu redirect URI (deve ser o mesmo registrado no Spotify)
const REDIRECT_URI = 'http://trackonnections/callback';
const CLIENT_ID = 'b0620bb044c64d529f747bb52b7233c2';
const CLIENT_SECRET = '6d197dce2d0a4874a49de7ddcea781b7';

// Endpoint de callback
app.get('/callback', async (req, res) => {
  const code = req.query.code; // O código de autorização do Spotify
  
  // Troque o código pelo token
  try {
    const tokenResponse = await axios.post(
      'https://accounts.spotify.com/api/token',
      querystring.stringify({
        grant_type: 'authorization_code',
        code,
        redirect_uri: REDIRECT_URI,
      }),
      {
        headers: {
          Authorization: `Basic ${Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64')}`,
        },
      }
    );
    
    const accessToken = tokenResponse.data.access_token;
    res.send(`Token de acesso: ${accessToken}`);
  } catch (error) {
    console.error(error);
    res.send('Erro ao trocar código por token');
  }
});

app.listen(PORT, () => {
  console.log(`Servidor rodando na porta ${PORT}`);
});
