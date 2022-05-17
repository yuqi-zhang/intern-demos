# Containers, Kubernetes and OpenShift

A demo constructed for the Toronto internship program orientation.

In the first demo, we will be building and running a simple go server locally.

In the second demo, we will be deploying it as an application to an OpenShift cluster via `oc`

With sections from previous year demos by:

[Angel Misevski](https://github.com/amisevsk)
[Jie Kang](https://github.com/jiekang)
[Josh Pinkney](https://github.com/JPinkney)

## Part 0: Setup

For the Container demo, we will be doing it via `podman`. If you do not have this locally (`which podman`) you can get it via `dnf install podman`.

For the Cluster demo, we will be using `oc` (the OpenShift Origin Client), but a lot of the commands are also the same via `kubectl`. You should have `oc` locally already (check with `which oc`). If you do not, we recommend downloading the latest version via OpenShift mirrors.

Using `oc` and `kubectl` from the commandline involves a whole lot of typing. It's really useful to have autocompletion for command names, arguments, resource types, and object names. To enable this (if it's not already in your `.bashrc`), you can run
```bash
source <(kubectl completion bash); source <(oc completion bash)
```
To get more information, use `oc completion --help`. (Note: if you're using `zsh`, that's supported too! Just replace `bash` with `zsh` above)

Finally, you should clone this repo locally (e.g. `git clone https://github.com/yuqi-zhang/intern-2022-demos.git`)

## Part 1: Container demo: running a basic web server

Inside the container repo we will have the necessary bits to build a web server. It is a simple frontend (`index.tmpl`) and golang backend `app.go` with the necessary `go.mod` and `go.sum` to build. You can build this locally (requires you to install golang) via `./build-local.sh` and then running the server via `./server`.

Now if you go to `http://localhost:8080/` you can see the simple server running.

Let us instead run that in a container. With podman installed, run:

`podman build -t localhost/go-server .`

To create the image. Then, `podman run -it -p 8080:8080 localhost/go-server` to start it.

Now it's running the same thing, but via a container.

You can also push the image to a registry, e.g.: `podman push localhost/go-server:latest quay.io/jerzhang/demo-go-server`

Once you are done, you can see containers with `podman ps -a` and `podman rm` the container.

## Part 2: Cluster demo: running the web server in an OpenShift cluster

The `openshift/manifests` directory contains the YAML files we'll be deploying to our cluster. 

You can *apply* a template to the cluster using the command
```bash
oc apply -f templates/<file>.yaml
```
You can also use
```bash
oc apply -f templates/
```
to apply *all* files in the templates folder at once.

____

First, let's login to our cluster. Go to the cluster URL provided. Ignore the security warnings, and choose the login with `htpasswd` option. Your username is your Red Hat id and your password is `openshift`.

Once inside, you can click on your name on the top right, and select `Copy login command`, which will bring you to another sign-on page. Login, hit `display token`, and you should see something like:

```bash
oc login --token=sha256~${TOKEN} --server=${URL}
```

Copy that, and run that in a local terminal, where you plan on applying the config files. We will be doing a lot of commands via the command line, but you can actually also do the same via the web console.

Once you've successfully authenticated, create a project in your own name: e.g. `oc new-project jerzhang`

And you can see projects with `oc project`.

From now on, whenever you run a command, it will be under this project (namespace).
____

Now, lets create our deployment:
```bash
oc apply -f manifests/deployment.yaml
```

This creates the web server we just did in the containers demo in our cluster as a deployment. The image we are using is `quay.io/jerzhang/demo-go-server:latest` which is what we just pushed.

we can check the status of our deployment using `oc get` and `oc describe`
```bash
oc get deployment demo-deployment
# output:
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
demo-deployment   0/1     1            0           2s
```
While we wait for everything to get started, we can also:
1. Check out the pods created by the deployment using `oc get po -l 'app=demo-app'`. Here, we're using a *label selector* to only get pods with label `app=demo-app`. Otherwise, we'd get all pods in the current namespace.
2. View the yaml we used for our deployment, with its current status using `oc get deploy demo-deployment -o yaml` (you can use `-o json` to output JSON as well!)

We've now got a deployment that contains our server running in Kubernetes! How do we access it from our browser?

Next, we need to create a service to route traffic to the set of pods maintained by our deployment:
```bash
oc apply -f manifests/service.yaml
```
and then we need to create a route to expose that service to the internet:
```bash
oc apply -f manifests/route.yaml
```
Note: routes are an OpenShift specific object. For base Kubernetes, you will have to set up ingress instead.

## Testing it out
Once you've created the route, you can get the URL you'll use to access the deployment from `oc`:
```bash
oc get routes
# output
NAME         HOST/PORT                                          PATH   SERVICES       PORT   TERMINATION   WILDCARD
demo-route   demo-route-<current-namespace>.<url-for-cluster>          demo-service   http                 None
```

Accessing this URL should show you the server we ran locally.

## Configuring our deployment

Our deployment currently has a replica of 1, meaning there is exactly 1 pod running for it.

What happens if something breaks?

```bash
oc delete pod/demo-deployment-<hash>
```

It will recover very fast (kubernetes is trying to reconcile the deployment). But that doesn't seem very good in terms of availability.

Let's try to scale the deployment up to three replicas using 
```bash
oc scale deploy demo-deployment --replicas=3
```

Wait for them to be ready
```bash
oc get deployment demo-deployment
# output:
NAME              READY   UP-TO-DATE   AVAILABLE   AGE
demo-deployment   1/3     3            1           6m30s
```

delete a pod:
```bash
oc delete pod/demo-deployment-<hash>
```

No downtime.

## Cleanup
To remove everything we've deployed thus far, you can use a label selector to delete all the objects we created in the demo:
```bash
oc delete all -l 'app=demo-app'
```
