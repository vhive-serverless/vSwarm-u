# vSwarm-u Website

## Theme template

For the documentation we use the [Just-the-docs](https://just-the-docs.github.io/just-the-docs/) theme. Refer to it for more details how to customize the documentation.

## Serve the website locally

In order to create new features on the website its usually more convenient to do this locally. I.e. by using the "livereload" feature one can see changes immediately. For more details see [here](https://jekyllrb.com/docs/installation/).

### Install dependencies
```
sudo apt-get install ruby-full build-essential zlib1g-dev
# Install jekyll
gem install jekyll bundler
```

### Serving
After setting up jekyll locally we are now ready to serve the website by the following command in the `docs/ directory of this repo.
```
bundle exec jekyll serve
```
Jekyll will build the website and serve it on your localhost. For the address check the command output. Usually this is (http://127.0.0.1:4000/ease_website/). Now make the changes you want and then re-execute the command above. Alternatively add `--livereload` to the command. Now whenever you save a file the rebuild and serving update will happen automatically.


## Generating Documentation (Markdown) files from Jupyter Notebook
We can generate documentation from jupyter notebooks if we already have a nice one.
To do this `jupyter` and the `nbconvert` module need to be installed:
```bash
sudo apt install jupyter-core
python -m pip install nbconvert -U
```
Export a notebook with:
```
jupyter nbconvert --to markdown <notebook/path> --output ./docs/<output/md/path>
```
Afterwards go to output file and integrate it with the remaining documentation.
