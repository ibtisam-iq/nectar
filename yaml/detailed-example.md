# Example: Using 'fruit' as a Key with Direct and Nested Values in YAML

YAML uses key-value pairs, where keys are strings and values can be strings, numbers, lists, or dictionaries. This guide shows how to use `fruit` as a key in two ways: (1) directly mapping to a value (string, number, list, dictionary), and (2) as a top-level dictionary key with nested content of varying value types. Follow these examples to master YAML’s flexibility.

## Part 1: 'fruit' as a Key with Direct Values
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
Let, we have a no. of fruits now with no additional attributes. So, to list all fruits, use a list with hyphens.
```yaml
fruit:
  - apple
  - orange
  - banana
```
- **Explanation**: `fruit` maps to a list `[apple, orange, banana]`. Use this for collections.

### 4. Dictionary Value
Let, we have the same no of fruits, but each has pricing attribute too. Use a dictionary to pair fruits with prices.
```yaml
fruit:
  apple: 10
  orange: 15
  banana: 20
```
- **Explanation**: `fruit` maps to a dictionary of key-value pairs, where keys are fruit names and values are prices. Use this for structured data.

---

## Part 2: 'fruit:' as a Top-Level Dictionary Key
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

## Key Takeaways
- **Direct Use (`fruit`)**: Use `fruit` for simple, single values (string, number, list, dictionary) when minimal structure is needed.
- **Dictionary Use (`fruit:`)**: Use `fruit:` to group related attributes in a dictionary, ideal for structured configs (e.g., Kubernetes manifests).
- Both approaches are valid; choose based on your data’s complexity.
- Practice these to build clear, flexible YAML structures.