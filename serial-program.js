const {SerialPort} = require('serialport');

const tangnano = new SerialPort({
    path: 'COM11',
    baudRate: 115200,
});

const msg = "abc";
console.log('Gerar um hash sha256 de "'+msg+'"');
tangnano.on('data', function (data) {
    console.log('Data In Text:', data.toString());
    console.log('Data In Hex:', data.toString('hex'));

    const binary = data.toString().split('').map((byte) => {
        return byte.charCodeAt(0).toString(2).padStart(8, '0');
    });
    console.log('Data In Binary: ', binary.join(' '));

    tangnano.write(Buffer.from([msg]));
});
