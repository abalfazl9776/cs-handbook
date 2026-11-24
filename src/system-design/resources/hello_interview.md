In this file, you will read what's about system design and specially about system design interview which are not present in other files.
# How to break down a problem and propose a solution?
1. Requirements (Functional and Non-Functional)
2. Core Entities
3. API or Interfaces
4. Data flow
5. High level design (Primary goal: satisfy FR)
6. Deep dives (Primary goal: satisfy NFR)

# Contents
## Data Modeling
Take a look at [steps of proposing a solution](#How%20to%20break%20down%20a%20problem%20and%20propose%20a%20solution?) in an interview and [different types of databases](./../../database.md#Different%20types%20of%20Databases).
What matters in data modeling (specially in an interview) is Specifying **core entities** and **how to store them**.
### Three Key Factors
1. Data volume - Where can data live? (single DB vs distributed)
2. Access patterns - How is data queried? (drives indexes and structure)
3. Consistency requirements - How strict? (ACID vs eventual consistency)

So takes these steps in demonstrating your data model:
1. Choose a DB - impacts how data is stored
2. Outline columns
3. Add primary and foreign keys
4. Determine what indexes you need
5. Determine whether to denormalize
6. Consider if sharding is needed, if yes, choose a partition key (%TODO how to choose a partition key%)
