from ultralytics import YOLO

model = YOLO('runs/detect/train7/weights/best.pt')  


# model.train(data="fall_detection_dataset/data.yaml", epochs=150, imgsz=640,patience=100)

metrics = model.val()
print(metrics)
