# Guide: Using 'fruit' as a Key with Direct, Nested, and Nested List Values in YAML

YAML uses key-value pairs, where keys are strings and values can be strings, numbers, lists, or dictionaries. This guide shows how to use `fruit` as a key in three ways: (1) directly mapping to a value, (2) as a top-level dictionary key with nested content, and (3) as a key for a nested list structure. Follow these examples to master YAML’s flexibility.

---

## Case 1: 'fruit' as a Key with Direct Values
Here, `fruit` is a key directly mapped to a single value. We assume we need to represent fruit-related data in the simplest form.

### 1. String Value
We just have one fruit. To name the fruit, use a string.
```yaml
fruit: apple
```
- **Explanation**: `fruit` maps to the string `apple`. Use this for a single value, like a fruit’s name.

### 2. Number Value
To show a numeric attribute, like price, use a number.
```yaml
fruit: 10
```
- **Explanation**: `fruit` maps to the number `10` (e.g., $10). Use this for quantities.

### 3. List Value
Let, we have a no. of fruits now with **no additional attributes**. So, to list all fruits, use a list with hyphens.
```yaml
fruit:
  - apple
  - orange
  - banana
```
- **Explanation**: `fruit` maps to a list `[apple, orange, banana]`. Use this for collections.

### 4. Dictionary Value
Let, we have the same no. of fruits, but each has **pricing attribute** too. Use a dictionary to pair fruits with prices.
```yaml
fruit:
  apple: 10
  orange: 15
  banana: 20
```
- **Explanation**: `fruit` maps to a dictionary of key-value pairs, where keys are fruit names and values are prices. Use this for structured data.

---

## Case 2: 'fruit:' as a Top-Level Dictionary Key
Here, `fruit:` is a key that serves as a top-level identifier for a dictionary, with nested key-value pairs. We assume we need to group multiple attributes about a fruit under `fruit:`. The nested values vary by type.

### 1. String Value (Nested)
To describe a fruit’s name, nest a string.
```yaml
fruit:
  name: apple
```
- **Explanation**: `fruit:` is a dictionary key. Its value is the nested dictionary `{name: apple}`, grouping the name attribute. Use this to organize single attributes.

### 2. Number Value (Nested)
To show a price, nest a number.
```yaml
fruit:
  price: 0.5
```
- **Explanation**: `fruit:` maps to a dictionary `{price: 0.5}`, grouping the price attribute. Use this for numeric properties.

### 3. List Value (Nested)
To list colors, nest a list.
```yaml
fruit:
  colors:
    - red
    - green
    - yellow
```
- **Explanation**: `fruit:` maps to a dictionary `{colors: [red, green, yellow]}`, grouping the colors list. Use this for nested collections.

### 4. Dictionary Value (Nested)
To detail attributes, nest a dictionary.
```yaml
fruit:
  details:
    origin: "IHS, UAF"
    weight: 182
    type: organic
```
- **Explanation**: `fruit:` maps to a dictionary `{details: {origin: USA, weight: 182, type: organic}}`, grouping detailed attributes. Use this for complex, nested data.

---

## Part 3: 'fruit:' as a Key for a Nested List
Assume we need to represent multiple categories of fruit-related data, each with a list of items, under `fruit:`.

### 1. Nested List
To categorize fruit types and colors, use a nested list structure.
```yaml
fruit:
  - types:
      - apple
      - orange
  - colors:
      - red
      - green
```
- **Explanation**: 
  - `fruit:` maps to a list, with each item (prefixed by `-`) being a dictionary.
  - Each dictionary (`types:`, `colors:`) contains a list (e.g., `- apple`, `- orange`).
  - Use this for complex, hierarchical data, like categorizing fruit attributes.
- **Step-by-Step**:
  1. `fruit:` is a list (items start with `-`).
  2. Each list item is a dictionary (e.g., `types:` or `colors:` with key-value pairs).
  3. Each dictionary’s value is a list (e.g., `- apple`, `- orange` under `types`).


### 2. Nested List of Dictionaries
To describe multiple fruit types with attributes and color lists, use a list of dictionaries with nested lists.
```yaml
fruit:
  - type: apple
    weight: 182
    colors:
      - red
      - green
  - type: orange
    weight: 200
    colors:
      - orange
```
- **Explanation**:
  - `fruit:` maps to a list of dictionaries, each representing a fruit type.
  - Each dictionary has keys `type`, `weight`, and `colors`, where `colors` is a nested list.
  - Use this for complex configurations, like detailing multiple fruits with attributes.
- **Step-by-Step**:
  1. `fruit:` is a list (items start with `-`).
  2. Each list item is a dictionary with keys `type`, `weight`, and `colors`.
  3. The `colors` key maps to a list (e.g., `- red`, `- green`).

---

## Key Takeaways
- **Direct Use (`fruit`)**: Use `fruit` for simple, single values (string, number, list, dictionary) when minimal structure is needed.
- **Dictionary Use (`fruit:`)**: Use `fruit:` to group related attributes in a dictionary, ideal for structured configs (e.g., Kubernetes manifests).
- **Nested List `fruit:`**: Use for hierarchical lists or configurations, like categorizing or detailing multiple fruits.
- Choose the structure based on data complexity.
- Practice these to build robust YAML configurations.
