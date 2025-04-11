# Politique d’Artsdata relative aux images

## Résumé de la politique (ne fait pas partie de la politique officielle)

* Artsdata n’entrepose pas d’images, seulement des URLs d’images (et les métadonnées qui peuvent y être associées).
* Lorsque la licence d’une image n’est pas précisée, l’utilisateur de données doit présumer qu’une image est protégée par le droit d’auteur.
* Un utilisateur ne devrait réutiliser une URL d’image que conformément aux fins pour lesquelles l’image a été publiée sur le site source.
* La responsabilité d’Artsdata se limite à la publication d’URL d’image sous forme de données ouvertes.

# Politique d’Artsdata relative aux images – Version 1.0 (version officielle)

## Comment Artsdata gère les informations relatives aux images

Artsdata met à disposition des données ouvertes de différentes natures. Parmi ces données, on retrouve des URLs d’images : par exemple, des URLs d’images promotionnelles d’événements ou d’images de profils d’artistes.

Artsdata n’extrait et n’entrepose que les URLs d’image et ne dépose en aucun cas de copies d’images sur ses serveurs. Artsdata n’extrait par ailleurs les URLs d’image que lorsque ces URLs constituent une métadonnée en lien avec une entité précise pour laquelle Artsdata a obtenu l’autorisation d’extraire les données, par exemple un événement ou un artiste. Lorsque des crédits photos et des mentions de licence sont disponible à la source, Artsdata s’assure d’extraire ces métadonnées et des les intégrer à l’intérieur d’un objet image (“schema:ImageObject”). Ainsi, les métadonnées d’image sont rendues accessibles au même titre que l’URL d’image et que les autres métadonnées décrivant l’entité dépeinte par l’image.

```
"image": {
  "@type": "ImageObject",
  "url": "--URL de l'image : image URL--",
  "usageInfo": "https://kg.artsdata.ca/doc/image-policy",
  "disambiguatingDescription": "--Image de [NOM DE L'ENTITÉ], provenant de [NOM DE DOMAINE DU SITE WEB] : Image of [ENTITY NAME], sourced from [WEBSITE DOMAIN NAME]--",
  "description": "--Alt texte, si disponible : Alt text, if available--",
  "sdDatePublished": "--Date à laquelle les métadonnées de l’ImageObject ont été générées : Date on which the ImageObject’s metadata was generated--"
  },
```
Note : Ce gabarit JSON-LD n’est fourni qu’à titre illustratif. La modélisation des `ImageObject` par Artsdata peut varier d’une source à l’autre et est susceptible d’évoluer dans le temps. Pour plus d’information sur la modélisation des entités de type `ImageObject`, consultez [cette discussion](https://github.com/culturecreates/artsdata-data-model/discussions/137). 

## Lignes directrices à l’intention des utilisateurs de données

À moins d’une mention de licence indiquant autrement, les utilisateurs doivent présumer que les images dont les URLs sont entreposées dans Artsdata sont protégées par le droit d’auteur.

Conformément aux ententes types de l’industrie, aux conventions collectives et aux lois en vigueur au Canada, une URL d’image ne devrait être utilisée qu’aux mêmes fins pour lesquelles l’image a été publiée sur le site source et dans les mêmes conditions. Par exemple, dans le cas d’une image promotionnelle pour un événement :  

* L’URL d’image ne devrait être utilisée qu’en lien avec l’événement auquel elle est associée;
* L’utilisateur devrait s’assurer d’inclure suffisamment de données à propos de l’événement afin que celui-ci soit désambiguïsable (c’est-à-dire qu’il puisse être distingué d’un autre événement similaire) ;
* Lorsque les données précisant l’URL de la page officielle de l’événement (c.-à-d. la page d’événement sur le site de l’organisateur officiel de l’événement) et/ou l’URL de la billetterie officielle de l’événement sont disponibles, l’utilisateur devrait inclure ces informations, en plus des autres données permettant de désambiguïser l’événement ;
* Si un crédit photo est disponible, celui-ci devrait être réutilisé avec l’URL d’image

L’objectif des conditions précitées est de faire en sorte que l’URL d’image soit utilisée conformément à l’intention de l’organisateur officiel qui a publié cette image (et des ayants droit qui lui ont accordé le droit de publier l’image).

En aucun cas un utilisateur d’Artsdata ne peut utiliser une URL d’image en lien avec une entité autre que l’événement auquel elle est associée, tel que décrit à la source des données.

En aucun cas une URL d’image ne devrait être associée à des métadonnées ou d’autres informations susceptibles de présenter de manière inexacte l’entité dépeinte par l’image ou de tromper un autre utilisateur (humain ou machine). Par exemple, il est interdit d’utiliser une URL d’image de manière à rediriger le consommateur vers un site de revente ou un site frauduleux, plutôt que vers le site de l’organisateur officiel ou de la billetterie officielle.  

## Limite de responsabilité

Dans le contexte des données ouvertes, la responsabilité des administrateurs d’Artsdata (au sens de la Communauté d’intérêt Artsdata, représentée par CAPACOA) se limite à la mise à disposition des URLs d’images (et des métadonnées qui y sont associées), telles qu’elles sont fournies dans les sources de données. Artsdata n’offre aucune garantie quant à l’exactitude, la récence ou la pérennité des URLs d’image. Artsdata ne peut être tenu responsable de tout préjudice découlant de l’utilisation de URLs d’image par les utilisateurs d’Artsdata.

## Rapports de violation

Toute utilisation contrevenant avec cette politique, avec les conditions d’utilisation du site soure et/ou avec les lois applicables au Canada peut être rapportée à Artsdata en écrivant à [cette adresse](artsdata@capacoa.ca). 

À la suite d’un rapport de violation, Artsdata pourrait prendre les mesures suivantes : 

* Retirer l’URL de l’image et les métadonnées associées du graphe de connaissances ;
* Remplacer provisoirement l’URL d’image par une autre URL de façon à retracer une utilisation fautive ;
* Retirer au contrevenant l’accès au graphe de connaissances.

## Consentement

En utilisant les données d’Artsdata, un utilisateur accepte cette politique.

Les utilisateurs contrevenant à cette politique pourraient se voir refuser l’accès à Artsdata.

[English version](https://kg.artsdata.ca/en/doc/image-policy)
