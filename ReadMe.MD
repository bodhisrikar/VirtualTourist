Title: Virtual Tourist

The Virtual Tourist app downloads and stores images from Flickr. The app allows users to drop pins on a map, as if they were stops on a tour. Users will then be able to download pictures for the location and persist both the pictures, and the association of the pictures with the pin.

TravelLocationsViewController: With this view controller user will be able to zoom in onto a location, drop a pin on the particular location. The location the user zoomed in or the location the user dropped the pin on will be persisted. When user taps on a pin they will be navigated to PhotoAlbumsViewController.

PhotoAlbumsViewController: If the images for the location are already present they are loaded instantaneously if not each image is downloaded and then stored in the database. When the image is being downloaded a loading indicator is shown to the user indicating the downloading activity. User can select the images by long pressing them. User can remove the selected images or refresh the entire collection.

To build the app, Download the project and run it.

## Requirements

Xcode 10
Swift 4.2 

## License

You are free to distribute the code and modify it.
