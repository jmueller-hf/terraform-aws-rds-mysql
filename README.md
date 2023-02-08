# Document
Files Explained
- **Main.tf** - This the core terraform file and contains the structure for the resource that you will be creating. There is already a empty pre-populated resource block ready to be populated with all of the properties to create your resource
- **Variable.tf** - This file desribe the variable structure and type used in your project. see the terrafrom offical documentation on how to populate this file for your resource. https://www.terraform.io/language/values/variables
- **Dev.tfvars** - This is a key/value file to store all of the variables used in your project. This file is environment specific hence the name "dev".tfvars
- **Output.tf** - This file displays the output of the reources being provisined as part of the main.tf file
- **Jenkinsfile** - This is jenkins pipeline to will be used for creating a jenkins pipeline for your terraform component. this pipeline also exposes the component via a rest api which can be called by CI/CD or anyother consumer such as a servicenow self-intake form or a gitops process.
