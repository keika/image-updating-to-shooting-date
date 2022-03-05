# image-updating-to-shooting-date
Set the date the image was created as the shooting date

- What is this program?
    - Set the file creation date and time to "DateTimeOriginal" and "DateTimeDigitized" in the Exif.
    - We assume a system (e.g., Amazon Photos) in which the image data imported by a scanner or other means does not have a date and time set and is sorted by the date and time the image was taken.
- Usage
    1. Rename config_sample.json to config.json and enter the folder path where the jpg image files are stored in input_path.
    1. Run the file image_date.ps1.