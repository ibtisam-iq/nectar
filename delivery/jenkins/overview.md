#### Continuous Integration, Delivery, and Deployment

- **Continuous Integration**: Automation to build and test applications whenever new commits are pushed into the branch.
- **Continuous Delivery**: Continuous Integration + Deploy application to production by "clicking on a button" (Release to customers is often, but on demand).
- **Continuous Deployment**: Continuous Delivery but without human intervention (Release to customers is ongoing).

![](./images/Delivery%20vs%20Deployment.png)
#### Pipeline Types

- **Scripted Pipeline**: Original, code validation happens while running the pipeline. Can’t restart. Executed all stages sequentially.
- **Declarative Pipeline**: Latest, first validates the code, and then runs the pipeline. Restarting from a specific stage is supported. A particular stage can be skipped based on the `when` directive.

---
