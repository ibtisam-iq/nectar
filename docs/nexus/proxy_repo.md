### Step 2: Add Maven Proxy Repo

```xml
<!-- First, we need to define the proxy repo -->
<server>
<id>maven-proxy-repo</id>               <!-- put the proxy repo name here -->
<username>your-username</username>      <!-- put the username of your nexus account here -->
<password>your-password</password>      <!-- put the password of your nexus account here -->
</server>
```

```xml
<!-- Then, we need to define the proxy settings -->
<mirror>
<id>nexus</id>
<!-- mirror all repositories, including central. Put * if you want to mirror all, put the name of the repo if you want to mirror only that repo -->               
<mirrorOf>*</mirrorOf>                     
<url>http://your-proxy-repo-url.com</url>  <!-- put the proxy repo url here -->
</mirror>

```
