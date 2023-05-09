# sup2neo4j

## Start neo4j

```bash
$ docker run \
  --publish=7474:7474 --publish=7687:7687 \
  --volume=$PWD/data \
  --env NEO4J_AUTH=neo4j/password \
  neo4j:latest
```

## Display all

```cyp
MATCH (n) RETURN n;
```

## Delete all

```cyp
MATCH ()-[r]->() DELETE r; MATCH (n) DELETE n;
```
