## Wazahat-1

*Mounting: Volumes are mounted at specific paths within a container's filesystem, overlaying the container image's root filesystem. Writes to these paths affect the volume, not the image.*

**Breakdown of the concept:**

* **"Mounting"**: volume ko container ke andar kisi specific path pe attach karna.
* **"Overlaying the container image's root filesystem"**: Ye path pe pehle se jo bhi files image me thi, wo override ho jati hain — volume us jagah le leta hai.
* **"Writes to these paths affect the volume, not the image"**: Jab aap likhte ho (e.g., log generate karna), to wo container image me permanent nahi hota, balki volume me store hota hai — jo zyada durable hota hai.

### 🔧 "Overlaying the container image's root filesystem" ka matlab:

Jab aap ek volume ko container ke andar kisi **existing path** (jaise `/app`, `/var/log`, etc.) pe mount karte ho, to:

> Wo **naya volume us purane path ko "cover" ya "replace" kar deta hai**.
> Matlab: Jo files us path pe image ke andar pehle se thi, wo temporarily "chhup" jaati hain jab tak volume mount hai.


### 🧠 Example:

Socho aapne ek Docker image banayi thi, jisme `/app` folder ke andar `main.py` file hai.

**Lekin**, jab aap container run karte waqt `/app` pe ek empty volume mount kar dete ho:

```yaml
volumeMounts:
  - name: my-volume
    mountPath: /app
```

Toh ab:

* Wo naya volume `/app` folder pe **overlay** ho gaya.
* Ab aapko container ke andar `/app/main.py` **nahi dikhega**.
* Kyunki `/app` ka original content **temporarily hide ho gaya** volume ke neeche.

### 🧺 Real-Life Analogy:

Socho ek table (image ka file system) pe ek **newspaper** padha hai (`main.py`), aur aapne us newspaper ke upar ek **blank bedsheet (volume)** bichha di.

Ab jab tak bedsheet bichhi hai, **aapko newspaper dikhai nahi dega** — lekin wo abhi bhi table ke neeche hai.
Jab bedsheet hataoge (volume remove), to newspaper phir se dikhne lagega.

---

