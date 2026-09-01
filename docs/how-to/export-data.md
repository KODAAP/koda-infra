# Exporter les données d'une enquête

Ce guide couvre tous les formats d'export disponibles dans Koda et les options avancées de filtrage.

## Formats disponibles

| Format | Extension | Bibliothèque | Cas d'usage |
|---|---|---|---|
| Excel | `.xlsx` | openpyxl / pandas | Analyse, reporting client |
| CSV | `.csv` | pandas | Import dans R, Python, Power BI |
| Shapefile | `.zip` (shp+dbf+shx+prj) | Fiona / GeoPandas | QGIS, ArcGIS, analyse spatiale |
| ZIP médias | `.zip` | Python zipfile | Archivage photos/audio/vidéo |

---

## Export Excel

### Via l'interface

1. Ouvrez le **Survey Dashboard** de l'enquête
2. Cliquez sur **Exporter** → **Excel (.xlsx)**
3. Attendez la notification de fin de traitement
4. Téléchargez le fichier depuis la notification ou la liste des exports

### Structure du fichier Excel généré

Le fichier Excel contient :
- **Feuille principale** : toutes les réponses de niveau racine (une ligne par soumission)
- **Feuilles repeat** : une feuille par groupe `repeat` du formulaire, avec une colonne `_parent_index` pour la jointure
- **Métadonnées** : colonnes `_id`, `_uuid`, `_submission_time`, `_submitted_by`

---

## Export CSV

Identique à l'export Excel mais en format texte brut, séparateur virgule, encodage UTF-8.

Utile pour :
```python
import pandas as pd
df = pd.read_csv("export_enquete.csv")
```

---

## Export Shapefile (données géographiques)

### Prérequis

Le formulaire doit contenir au moins une question de type :
- `geopoint` → export en couche de **points**
- `geotrace` → export en couche de **lignes**
- `geoshape` → export en couche de **polygones**

### Contenu du ZIP

```
export_enquete_shp.zip
├── enquete.shp      # Géométries
├── enquete.dbf      # Attributs (réponses)
├── enquete.shx      # Index spatial
└── enquete.prj      # Projection (WGS84 / EPSG:4326)
```

### Ouvrir dans QGIS

1. Décompressez le ZIP
2. Dans QGIS : **Couche** → **Ajouter une couche** → **Couche vecteur**
3. Sélectionnez le fichier `.shp`

---

## Export ZIP médias

Récupère tous les fichiers multimédias (photos, enregistrements audio, vidéos) attachés aux soumissions.

### Structure du ZIP

```
medias_enquete.zip
├── uuid-soumission-1/
│   ├── photo_1.jpg
│   └── audio_1.mp3
├── uuid-soumission-2/
│   └── photo_1.jpg
└── ...
```

---

## Suivi et historique des exports

Tous les exports générés sont listés dans l'onglet **Exports** du Survey Dashboard :

| Colonne | Description |
|---|---|
| Format | Type d'export (Excel, SHP, ZIP...) |
| Statut | En cours / Terminé / Erreur |
| Date | Horodatage de la demande |
| Taille | Taille du fichier généré |
| Action | Télécharger / Supprimer |

---

## Monitoring des tâches d'export

En cas de problème, consultez Flower pour diagnostiquer :

```
http://localhost:5555  (dev)
https://koda.insuco.net/flower  (prod)
```

Filtrez les tâches par nom `export_` pour voir uniquement les tâches d'export.

---

## Limites et bonnes pratiques

!!! tip "Enquêtes volumineuses"
    Pour les enquêtes avec plus de 5 000 soumissions, préférez lancer les exports en dehors des heures de pointe. Le traitement peut prendre plusieurs minutes.

!!! warning "Expiration des fichiers"
    Les fichiers d'export sont stockés dans `backend/media/exports/`. Ils ne sont pas supprimés automatiquement. Pensez à nettoyer régulièrement les anciens exports en production.
