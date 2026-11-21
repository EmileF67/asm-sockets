## **Les erreurs de socket**

| Erreur               | Cause possible                      | Comportement                          |
| -------------------- | ----------------------------------- | ------------------------------------- |
| `-EAFNOSUPPORT` (97) | Famille d'adresse invalide          | Erreur fatale                         |
| `-EINVAL` (22)       | Paramètres invalides                | Erreur fatale, vérifier les arguments |
| `-EMFILE` (24)       | Trop de FD ouverts par le processus | Fermer des ressources                 |
| `-ENFILE` (23)       | Limite globale de FD atteinte       | Erreur système                        |

## **Les erreurs de connexion**

| Erreur                | Cause                          | Comportement                    |
| --------------------- | ------------------------------ | ------------------------------- |
| `-ECONNREFUSED` (111) | Aucun serveur n'écoute         | Informer l'utilisateur, quitter |
| `-ETIMEDOUT` (110)    | Timeout de connexion           | Quitter ou retenter             |
| `-EHOSTUNREACH` (113) | Hôte inaccessible              | Quitter ou retenter             |
| `-ENETUNREACH` (101)  | Réseau inaccessible            | Quitter                         |
| `-EINTR` (4)          | Appel interrompu par un signal | Généralement réessayer          |

## **Les erreurs d'envoi**

| Erreur              | Cause                              | Comportement                        |
| ------------------- | ---------------------------------- | ----------------------------------- |
| `-EPIPE` (32)       | Connexion fermée côté distant      | Fermer et quitter                   |
| `-ECONNRESET` (104) | Connexion réinitialisée            | Fermer et quitter                   |
| `-EAGAIN` (11)      | Envoi non disponible immédiatement | Attendre ou réessayer selon le mode |
| `-EINTR` (4)        | Syscall interrompu                 | Réessayer                           |