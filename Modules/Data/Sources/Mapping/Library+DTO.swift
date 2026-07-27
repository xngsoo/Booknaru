import Foundation
import CoreLocation
import Domain

extension Library {
    init(_ doc: LibSrchByBookResponse.LibDoc) {
        // 위경도는 문자열로 오고, 둘 다 있어야 좌표가 성립한다
        let coordinate: CLLocationCoordinate2D? = {
            guard let latString = doc.latitude, let lat = Double(latString),
                  let lngString = doc.longitude, let lng = Double(lngString)
            else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }()
        
        self.init(code: doc.libCode,
                  name: doc.libName,
                  address: doc.address,
                  coordinate: coordinate,
                  phone: doc.tel,
                  homepage: doc.homepage.flatMap(URL.init(string: )),
                  operatingTime: doc.operatingTime,
                  closed: doc.closed
        )
    }
}
