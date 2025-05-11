# Conditions pour les fournisseurs de données

_Version 0.1 (ébauche)_

Le Contributeur qui accepte de fournir des données au graphe de connaissance Artsdata autorise le personnel d’Artsdata<sup>1</sup> à procéder aux activités d’extraction-transformation-chargement (ETC) des données suivantes :

- Extraire les données avec l’option technologique la plus appropriée selon les circonstances du Contributeur (voir la liste des [techniques d’extraction](https://culturecreates.github.io/artsdata-data-model/architecture/overview.fr.html#fournisseurs-de-donn%C3%A9es)).
- Transformer ces données au format RDF conformément au[ modèle de données Artsdata](https://culturecreates.github.io/artsdata-data-model/index.fr.html) (lequel est 100% conforme aux recommandations de Google) ;
- Entreposer les données ainsi extraites et transformées dans une instance de base de données graphe dédiée aux données du Contributeur et répertoriée dans la [liste des fournisseurs de données d’Artsdata](https://kg.artsdata.ca/query/show?sparql=feeds_all&title=Data+Feeds) ; 
- Mettre les données du Contributeur à disposition pour les consommateurs de données par le biais du terminal SPARQL et des APIs d’Artsdata selon la licence [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/deed.fr) et/ou les autres licences copyleft employées par le Contributeur ;
- Générer et publier des métadonnées administratives de traçabilité indiquant le Contributeur comme la source des données contribuées ;
- Attribuer des pointages aux données selon leur niveau d’autorité, de fiabilité et d’exhaustivité ;
- Attribuer des identifiants Artsdata aux entités principales des données du Contributeur, lorsque celles-ci ne s’en sont pas encore vu attribuer, ou lier les entités principales à leur identifiant Artsdata lorsque celui-ci existe déjà ;
- Réaliser diverses activités d’enrichissement sémantique des données, comme par exemple :
  - Détecter et corriger les erreurs mineures dans la syntaxes des données ;
  - Détecter le fuseau horaire du lieu, attribuer un identifiant de fuseau horaire au lieu ;
  - Ajouter le fuseau horaire des dates/heures, lorsque celui-ci est manquant, ou le corriger, lorsque celui-ci est inexact ;
  - Transformer les URL d’image en schema:ImageObject, conformément à la [politique d’images d’Artsdata](https://kg.artsdata.ca/fr/doc/image-policy) ; 
  - Lier les entités secondaires identifiables (par exemple, des personnes, des organismes ou de lieux) à des [identifiants pérennes](https://culturecreates.github.io/artsdata-data-model/identifier-recommendations.fr.html) existants (identifiant Artsdata, identifiant Wikidata, ISNI) ;
  - Intégrer des points de données additionnels récupérés par le biais des identifiants pérennes. 

Pour toutes questions à propos de ces conditions, veuillez contacter l’équipe d’Artsdata à artsdata@capacoa.ca. 

<sup>1</sup> Par _personnel d’Artsdata_, on entend le personnel de CAPACOA, de La culture crée et/ou tout autre tiers autorisé à contribuer à l’intendance graphe de connaissances Artsdata.
