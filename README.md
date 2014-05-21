# ImageSvd

[About page](http://ilyakava.tumblr.com/post/86408872127/gerhard-richter-svd-and-me).

## Installation

Add this line to your application's Gemfile:

    gem 'image_svd'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install image_svd

## Usage

`image_svd --help`

A prerequisite is to have [imagemagick](http://www.imagemagick.org/), and a ruby version 1.9.2 or greater installed.

`image_svd -i ~/Downloads/svd_photos/in_RichterfuneralM.jpg -n 10`
will create a new image in the current directory using 10 singular values.

Be warned! Compression is by no means quick! A 200x300 image takes 15 seconds on my computer. Finding the eigenvalues of a matrix is no easy computational task (O(n!) by brute force, O(n<sup>2.3</sup>) by super fancy approximation).

## Contributing

1. Fork it ( http://github.com/<my-github-username>/image_svd/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
