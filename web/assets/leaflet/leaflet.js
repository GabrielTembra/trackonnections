// Função para inicializar o mapa
function initializeMap(containerId, initialLat, initialLng, initialZoom) {
    // Cria o mapa e define a posição inicial e o nível de zoom
    var map = L.map(containerId).setView([initialLat, initialLng], initialZoom);
  
    // Adiciona uma camada de tiles do OpenStreetMap
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors',
    }).addTo(map);
  
    // Adiciona um marcador inicial
    L.marker([initialLat, initialLng]).addTo(map).bindPopup('Localização inicial').openPopup();
  
    // Permite adicionar marcadores ao clicar no mapa
    map.on('click', function (e) {
      var lat = e.latlng.lat;
      var lng = e.latlng.lng;
  
      L.marker([lat, lng]).addTo(map).bindPopup(`Lat: ${lat}, Lng: ${lng}`).openPopup();
    });
  
    console.log('Mapa inicializado com sucesso');
  }
  
  // Exemplo de chamada da função (pode ser removida se você chamar de outra forma)
  document.addEventListener('DOMContentLoaded', function () {
    // Inicializa o mapa no contêiner com ID 'map'
    initializeMap('map', 51.505, -0.09, 13);
  });
  